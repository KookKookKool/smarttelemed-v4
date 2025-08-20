// lib/core/device/yuwell_glucose.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';


/// อ่านค่า Glucose จาก Glucose Service (0x1808) / Glucose Measurement (0x2A18)
/// ส่งออก Stream<Map<String,String>> เช่น:
/// { mgdl: "102", mmol: "5.66", seq: "12", ts: "2025-08-18 10:32:11", raw: "xx xx ..." }
class YuwellGlucose {
  YuwellGlucose({required this.device});
  final BluetoothDevice device;

  static final Guid _svcGlucose =
      Guid('00001808-0000-1000-8000-00805f9b34fb'); // Glucose Service
  static final Guid _chrMeasurement =
      Guid('00002a18-0000-1000-8000-00805f9b34fb'); // Glucose Measurement

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _sub;

  /// เริ่ม subscribe และคืน Stream<Map<String,String>>
  Future<Stream<Map<String, String>>> parse() async {
    // ให้แน่ใจว่ายังเชื่อมต่อ
    final st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 10));
    }

    // ค้นหา services / characteristics
    final services = await device.discoverServices();
    final svc = services.firstWhere(
      (s) => s.uuid == _svcGlucose,
      orElse: () => throw Exception('ไม่พบ Glucose Service (0x1808)'),
    );
    final chr = svc.characteristics.firstWhere(
      (c) => c.uuid == _chrMeasurement,
      orElse: () => throw Exception('ไม่พบ Glucose Measurement (0x2A18)'),
    );

    // เปิด notify/indicate
    await chr.setNotifyValue(true);

    // Subscribe
    await _sub?.cancel();
    _sub = chr.lastValueStream.listen((data) {
      final out = _parseGlucoseMeasurement(data);
      if (out != null) _controller.add(out);
    });

    // กระตุ้นอ่านครั้งแรก (บางรุ่นจำเป็น)
    try { await chr.read(); } catch (_) {}

    return _controller.stream;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  // ----------------- Parser: Glucose Measurement (0x2A18) -----------------
  //
  // Byte layout (ตามสเปค):
  // [0]  Flags:
  //      bit0: Time Offset present (int16)
  //      bit1: Glucose Concentration, Type & Sample Location present
  //      bit2: Units (0 = kg/L, 1 = mol/L)
  //      bit3: Sensor Status Annunciation present (uint16)
  //      bit4: Context Information Follows (ไม่ parse ที่นี่)
  // [1..2]   Sequence Number (uint16, little-endian)
  // [3..9]   Base Time (7 bytes: year LSB, MSB, month, day, hour, min, sec)
  // [opt2]   Time Offset (int16) if bit0
  // [opt?]   Glucose Concentration (SFLOAT16) + Type/Location (uint8) if bit1
  // [opt2]   Sensor Status (uint16) if bit3
  //
  // เราสนใจค่า Glucose Concentration:
  // - ถ้า Units=mol/L → mmol/L = value * 1000, mg/dL = mmol/L * 18.0
  // - ถ้า Units=kg/L  → mg/dL = value * 100000, mmol/L = mg/dL * 0.0555
  Map<String, String>? _parseGlucoseMeasurement(List<int> data) {
    if (data.length < 10) return null; // อย่างน้อยต้องมี flags + seq + base time

    int i = 0;
    final flags = data[i++];
    final hasTimeOffset = (flags & 0x01) != 0;
    final hasConcTypeLoc = (flags & 0x02) != 0;
    final isMolPerL = (flags & 0x04) != 0; // 1=mol/L, 0=kg/L
    final hasStatus = (flags & 0x08) != 0;
    // final hasContext = (flags & 0x10) != 0;

    // Sequence Number
    if (data.length < i + 2) return null;
    final seq = data[i] | (data[i + 1] << 8);
    i += 2;

    // Base Time
    if (data.length < i + 7) return null;
    final year = data[i] | (data[i + 1] << 8);
    final month = data[i + 2];
    final day = data[i + 3];
    final hour = data[i + 4];
    final minute = data[i + 5];
    final second = data[i + 6];
    i += 7;
    final ts = _fmtTs(year, month, day, hour, minute, second);

    // Time Offset (ถ้ามี)
    int? timeOffset;
    if (hasTimeOffset) {
      if (data.length < i + 2) return null;
      timeOffset = _toInt16le(data[i], data[i + 1]);
      i += 2;
    }

    double? mmolL;
    double? mgdL;

    // Glucose Concentration + Type/Location (ถ้ามี)
    if (hasConcTypeLoc) {
      if (data.length < i + 3) return null; // SFLOAT16 (2) + type/loc (1)
      final conc = _decodeSfloat16(data[i], data[i + 1]);
      i += 2;

      // type/location (ไม่ใช้ในการคำนวณ แต่ถ้าต้องการสามารถเก็บได้)
      final _typeLoc = data[i];
      i += 1;

      if (conc != null) {
        if (isMolPerL) {
          // mol/L → mmol/L → mg/dL
          mmolL = conc * 1000.0;
          mgdL = mmolL * 18.0;
        } else {
          // kg/L → mg/dL → mmol/L
          mgdL = conc * 100000.0;
          mmolL = mgdL * 0.0555; // approx conversion for glucose
        }
      }
    }

    // Sensor Status (ถ้ามี) → ข้ามได้ ถ้าอยากเก็บ:
    if (hasStatus) {
      if (data.length >= i + 2) {
        final _status = data[i] | (data[i + 1] << 8);
        i += 2;
        // สามารถ map เป็นข้อความแจ้งเตือนได้ตามสเปค หากต้องการ
      }
    }

    // ไม่มี concentration → ไม่ส่งค่า
    if (mmolL == null && mgdL == null) return null;

    // ถ้าได้ค่าใดค่าหนึ่ง ให้คำนวณอีกหน่วยเพื่อเติมความครบถ้วน
    if (mmolL == null && mgdL != null) {
      mmolL = mgdL * 0.0555;
    } else if (mgdL == null && mmolL != null) {
      mgdL = mmolL * 18.0;
    }

    return {
      'mgdl': mgdL!.toStringAsFixed(0),
      'mmol': mmolL!.toStringAsFixed(2),
      'seq': seq.toString(),
      'ts': ts,
      if (timeOffset != null) 'time_offset': timeOffset.toString(),
      'raw': _hex(data),
    };
  }

  // ---------- helpers ----------
  int _toInt16le(int b0, int b1) {
    int v = (b1 << 8) | (b0 & 0xFF);
    if (v & 0x8000 != 0) v = v - 0x10000;
    return v;
  }

  /// IEEE-11073 16-bit SFLOAT → double
  double? _decodeSfloat16(int b0, int b1) {
    int raw = (b1 << 8) | (b0 & 0xFF);
    // Special values (NaN/±INF) → return null
    if (raw == 0x07FF || raw == 0x0800 || raw == 0x07FE) return null;

    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;

    // sign-extend
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x0008) != 0) exponent |= ~0x000F;

    return mantissa * math.pow(10.0, exponent).toDouble();
  }

  String _fmtTs(int y, int m, int d, int h, int min, int s) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${y.toString().padLeft(4, '0')}-${two(m)}-${two(d)} ${two(h)}:${two(min)}:${two(s)}';
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
