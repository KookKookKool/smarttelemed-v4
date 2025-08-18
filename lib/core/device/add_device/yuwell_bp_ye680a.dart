// lib/core/device/yuwell_bp_ye680a.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class YuwellBpYe680a {
  YuwellBpYe680a({required this.device});

  final BluetoothDevice device;

  // Blood Pressure (0x1810) / Measurement (0x2A35)
  static final Guid _svcBp = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid _chrBp = Guid('00002a35-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _valueSub;

  /// เริ่ม subscribe แล้วส่งค่า SYS/DIA/PUL (และ MAP/เวลา/หน่วย) เป็น Map<String,String>
  /// ตัวอย่าง Map:
  /// { sys: "123", dia: "78", pul: "72", map: "93", unit: "mmHg", ts: "2025-08-18 10:25:30", raw: "fe 0a ..." }
  Future<Stream<Map<String, String>>> parse() async {
    // ให้แน่ใจว่ายังเชื่อมต่อ
    final st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 10));
    }

    // ค้นหา service / characteristic
    final services = await device.discoverServices();
    final svc = services.firstWhere(
      (s) => s.uuid == _svcBp,
      orElse: () => throw Exception('ไม่พบ Blood Pressure service (0x1810)'),
    );
    final chr = svc.characteristics.firstWhere(
      (c) => c.uuid == _chrBp,
      orElse: () => throw Exception('ไม่พบ Blood Pressure Measurement (0x2A35)'),
    );

    // เปิด notify/indicate
    await chr.setNotifyValue(true);

    // สมัครรับค่า
    await _valueSub?.cancel();
    _valueSub = chr.lastValueStream.listen((data) {
      final parsed = _parseBpMeasurement(data);
      if (parsed != null) {
        _controller.add(parsed);
      }
    });

    // กระตุ้นอ่านครั้งแรก (บางรุ่นจำเป็น)
    try { await chr.read(); } catch (_) {}

    return _controller.stream;
  }

  /// ปิดการใช้งานและสตรีม
  Future<void> dispose() async {
    await _valueSub?.cancel();
    await _controller.close();
  }

  // ----------------- Parsing 0x2A35 (Blood Pressure Measurement) -----------------
  //
  // flags (8-bit):
  // bit0: 0=mmHg, 1=kPa
  // bit1: timestamp present (7 bytes)
  // bit2: pulse rate present (SFLOAT16)
  // bit3: userId present (uint8)
  // bit4: measurement status present (uint16)
  //
  // Layout:
  // [0] flags
  // [1..2] Systolic (SFLOAT16)
  // [3..4] Diastolic (SFLOAT16)
  // [5..6] MAP (SFLOAT16)
  // [+7 if bit1] Timestamp (year LSB, year MSB, month, day, hour, minute, second)
  // [+2 if bit2] Pulse (SFLOAT16)
  Map<String, String>? _parseBpMeasurement(List<int> data) {
    if (data.isEmpty) return null;

    int i = 0;
    final flags = data[i++];

    final isKpa = (flags & 0x01) != 0;
    final hasTs = (flags & 0x02) != 0;
    final hasPulse = (flags & 0x04) != 0;
    // final hasUser = (flags & 0x08) != 0;
    // final hasStatus = (flags & 0x10) != 0;

    if (data.length < i + 6) return null;

    final sS = _decodeSfloat16(data[i], data[i + 1]); i += 2; // SYS
    final dS = _decodeSfloat16(data[i], data[i + 1]); i += 2; // DIA
    final mS = _decodeSfloat16(data[i], data[i + 1]); i += 2; // MAP

    if (sS == null || dS == null || mS == null) return null;

    DateTime? ts;
    if (hasTs && data.length >= i + 7) {
      final year = data[i] | (data[i + 1] << 8);
      final month = data[i + 2];
      final day = data[i + 3];
      final hour = data[i + 4];
      final minute = data[i + 5];
      final second = data[i + 6];
      i += 7;
      ts = DateTime.tryParse(
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}',
      );
    }

    double? pulse;
    if (hasPulse && data.length >= i + 2) {
      pulse = _decodeSfloat16(data[i], data[i + 1]);
      i += 2;
    }

    // แปลงหน่วย (ถ้า kPa → mmHg)
    const kPa2mmHg = 7.50062;
    final sys = isKpa ? (sS * kPa2mmHg) : sS;
    final dia = isKpa ? (dS * kPa2mmHg) : dS;
    final map = isKpa ? (mS * kPa2mmHg) : mS;
    final pul = (pulse != null)
        ? (isKpa ? pulse /* pulse เป็น bpm ไม่ต้องแปลง */ : pulse)
        : null;

    // สร้างผลลัพธ์
    return {
      'sys': sys.toStringAsFixed(0),
      'dia': dia.toStringAsFixed(0),
      'map': map.toStringAsFixed(0),
      'pul': pul?.toStringAsFixed(0) ?? '-', // อาจไม่มีในแพ็กเก็ต
      'unit': isKpa ? 'mmHg (from kPa)' : 'mmHg',
      'ts': ts?.toIso8601String() ?? '',
      'raw': _hex(data),
    };
  }

  /// IEEE-11073 16-bit SFLOAT → double (รองรับ NaN/INF พื้นฐาน)
  double? _decodeSfloat16(int b0, int b1) {
    int raw = (b1 << 8) | (b0 & 0xFF);

    // พิเศษตามสเปค (NaN/INF ฯลฯ) – ตัดทิ้งเป็น null
    if (raw == 0x07FF || raw == 0x0800 || raw == 0x07FE) return null;

    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;

    // sign-extend
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x0008) != 0) exponent |= ~0x000F;

    return mantissa * math.pow(10.0, exponent).toDouble();
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
