// lib/core/device/add_device/mibfs_05hm.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Mi Body Fat Scale (MIBFS 05HM)
/// ✅ โฟกัสหลัก: Xiaomi proprietary 0x1530 / 0x1531 (Notify/Write)
///    - น้ำหนัก (kg) = (data[11] | data[12] << 8) / 200.0
///    - ค่าคงที่/ชั่งนิ่งแล้ว: (data[1] & 0x20) != 0
/// ❗ 0x2A9C (Body Composition Measurement) ใช้เป็น fallback เท่านั้น
class MiBfs05hm {
  MiBfs05hm({required this.device});
  final BluetoothDevice device;

  // GATT UUIDs (บริการมาตรฐาน)
  static final Guid _svcBody = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid _chr2A9C = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  // Xiaomi proprietary (…-3512-2118-0009AF100700)
  static final Guid _chr1530 = Guid('00001530-0000-3512-2118-0009af100700'); // notify/write
  static final Guid _chr1531 = Guid('00001531-0000-3512-2118-0009af100700'); // notify/write
  static final Guid _chr1532 = Guid('00001532-0000-3512-2118-0009af100700'); // write (ไม่จำเป็นก็ได้)

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _sub;

  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();
    final services = await device.discoverServices();

    // --- เลือก Characteristic: พยายามใช้ 1530/1531 ก่อน ---
    BluetoothCharacteristic? chr =
        _findChrAnywhere(services, [_chr1530, _chr1531], requireNotify: true);

    // ถ้าไม่เจอ 1530/1531 → ลอง 2A9C
    chr ??= _findChr(
      _findService(services, _svcBody),
      _chr2A9C,
      requireNotifyOrIndicate: true,
    );

    if (chr == null) {
      throw Exception('MIBFS: ไม่พบ 0x1530/0x1531 หรือ 0x2A9C');
    }

    try { await chr.setNotifyValue(true); } catch (_) {}
    await _sub?.cancel();
    _sub = chr.lastValueStream.listen((data) {
      if (chr!.uuid == _chr1530 || chr.uuid == _chr1531) {
        _on153x(data);
      } else {
        _on2a9c(data);
      }
    }, onError: (_) {});

    // กระตุ้นอ่านครั้งแรก (บางรุ่น)
    try { await chr.read(); } catch (_) {}

    return _controller.stream;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  // ---------- 1530/1531 parser (หลัก) ----------
  // ฟอร์แมตที่พบทั่วไป:
  //  data[11..12] LE -> rawWeight (divide 200) => kg
  //  stabilized flag  -> (data[1] & 0x20) != 0
  //  impedance (บางเฟรม) -> (data[9] | data[10]<<8)
  // หมายเหตุ: หน่วยในเฟรมมักจะมีบิตบอก แต่เราคงที่เป็น kg เพื่อความคงเส้นคงวา
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  double?  _lastKg;

  void _on153x(List<int> data) {
    if (data.length < 13) return;

    final raw = (data[11] | (data[12] << 8)) & 0xFFFF;
    final kg  = raw / 200.0;

    // ความสมเหตุผลของน้ำหนัก
    if (kg <= 10.0 || kg >= 300.0) return;

    // รอ "ชั่งนิ่งแล้ว"
    final stabilized = (data.length > 1) && ((data[1] & 0x20) != 0);

    // ลดสแปม: ถ้าน้ำหนักไม่เปลี่ยน และมาภายใน 120ms ไม่ส่งซ้ำ
    final now = DateTime.now();
    if (_lastKg != null &&
        (kg - _lastKg!).abs() < 0.01 &&
        now.difference(_lastEmit).inMilliseconds < 120) {
      return;
    }
    _lastKg = kg;
    _lastEmit = now;

    final out = <String, String>{
      'weight_kg': kg.toStringAsFixed(2),
      'stable'   : stabilized ? '1' : '0',
      'src'      : '153x',
      'raw1530'  : _hex(data),
    };

    // impedance (ถ้ามี)
    if (data.length >= 11) {
      final imp = (data[9] | (data[10] << 8)) & 0xFFFF;
      if (imp >= 200 && imp <= 2000) {
        out['impedance_ohm'] = imp.toString();
      }
    }

    _controller.add(out);
  }

  // ---------- 2A9C fallback ----------
  void _on2a9c(List<int> data) {
    if (data.length < 2) return;

    int i = 0;
    final flags = data[i] | (data[i + 1] << 8);
    i += 2;

    final isSI         = (flags & 0x0001) == 0;   // 0 = SI(kg,m)
    final hasTs        = (flags & 0x0002) != 0;
    final hasUser      = (flags & 0x0004) != 0;

    double? readVal() {
      if (data.length < i + 2) return null;
      final v = _decodeSfloat16(data[i], data[i + 1]);
      i += 2;
      return v;
    }

    if (hasTs && data.length >= i + 7) i += 7; // timestamp
    if (hasUser && data.length >= i + 1) i += 1; // userId

    final out = <String, String>{};

    // ตามสเปค: ฟิลด์จะเรียงตามบิต 3..11
    final bits = <int, String>{
      0x0008: 'basal_kJ',
      0x0010: 'muscle_percent',
      0x0020: 'muscle_mass_kg',
      0x0040: 'fat_free_mass_kg',
      0x0080: 'soft_lean_mass_kg',
      0x0100: 'body_water_mass_kg',
      0x0200: 'impedance_ohm',
      0x0400: isSI ? 'weight_kg' : 'weight_lb',
      0x0800: isSI ? 'height_m'  : 'height_in',
    };

    for (final entry in bits.entries) {
      final bit = entry.key;
      final key = entry.value;
      if ((flags & bit) != 0) {
        final v = readVal();
        if (v == null) break;
        out[key] = _fmt(v);
      }
    }

    // คำนวณ BMI ถ้ามีทั้งน้ำหนักและส่วนสูง
    final w = double.tryParse(out[isSI ? 'weight_kg' : 'weight_lb'] ?? '');
    final h = double.tryParse(out[isSI ? 'height_m' : 'height_in'] ?? '');
    if (w != null && h != null && h > 0) {
      final bmi = isSI ? (w / (h * h)) : (w / ((h * 0.0254) * (h * 0.0254)));
      out['bmi'] = bmi.toStringAsFixed(1);
    }

    if (out.isNotEmpty) {
      out['src'] = '2A9C';
      _controller.add(out);
    }
  }

  // ---------- BLE ----------
  Future<void> _ensureConnected() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
    var st = await device.connectionState.first;
    if (st == BluetoothConnectionState.connected) return;

    if (st == BluetoothConnectionState.connecting) {
      st = await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected ||
                        s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 12),
                   onTimeout: () => BluetoothConnectionState.disconnected);
      if (st == BluetoothConnectionState.connected) return;
    }
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
    await device.connectionState
        .where((s) => s == BluetoothConnectionState.connected ||
                      s == BluetoothConnectionState.disconnected)
        .first
        .timeout(const Duration(seconds: 12));
  }

  // ---------- find helpers ----------
  BluetoothService? _findService(List<BluetoothService> list, Guid id) {
    for (final s in list) {
      if (s.uuid == id) return s;
    }
    return null;
  }

  BluetoothCharacteristic? _findChr(
    BluetoothService? s,
    Guid id, {
    bool requireNotifyOrIndicate = false,
  }) {
    if (s == null) return null;
    for (final c in s.characteristics) {
      final ok = !requireNotifyOrIndicate || c.properties.notify || c.properties.indicate;
      if (c.uuid == id && ok) return c;
    }
    return null;
  }

  BluetoothCharacteristic? _findChrAnywhere(
    List<BluetoothService> list,
    List<Guid> ids, {
    bool requireNotify = false,
  }) {
    for (final s in list) {
      for (final c in s.characteristics) {
        for (final id in ids) {
          final ok = !requireNotify || c.properties.notify;
          if (c.uuid == id && ok) return c;
        }
      }
    }
    return null;
  }

  // ---------- utils ----------
  double? _decodeSfloat16(int b0, int b1) {
    int raw = (b1 << 8) | (b0 & 0xFF);
    if (raw == 0x07FF || raw == 0x0800 || raw == 0x07FE) return null; // NaN/INF
    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x0008) != 0) exponent |= ~0x000F;
    return mantissa * math.pow(10.0, exponent).toDouble();
  }

  String _fmt(double v) => v.toStringAsFixed(v.abs() >= 100 ? 1 : 2);
  String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join(' ');
}
