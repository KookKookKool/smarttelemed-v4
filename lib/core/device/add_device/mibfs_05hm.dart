// lib/core/device/add_device/mibfs_05hm.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

class MiBfs05hm {
  MiBfs05hm({required this.device});
  final BluetoothDevice device;

  // Body Composition (มาตรฐาน)
  static final Guid _svcBody = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid _chrMeas = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  // Xiaomi proprietary (พบในรูปที่ส่งมา)
  static final Guid _chr1530 = Guid('00001530-0000-3512-2118-0009af100700');
  static final Guid _chr1531 = Guid('00001531-0000-3512-2118-0009af100700');
  static final Guid _chr1532 = Guid('00001532-0000-3512-2118-0009af100700');

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _sub2a9c;
  final List<StreamSubscription<List<int>>> _subs153x = [];

  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();
    final svcs = await device.discoverServices();

    // --- subscribe 2A9C ถ้ามี ---
    BluetoothCharacteristic? chr2a9c;
    for (final s in svcs) {
      if (s.uuid == _svcBody) {
        for (final c in s.characteristics) {
          if (c.uuid == _chrMeas && (c.properties.indicate || c.properties.notify)) {
            chr2a9c = c;
            break;
          }
        }
      }
    }
    if (chr2a9c != null) {
      try { await chr2a9c.setNotifyValue(true); } catch (_) {}
      await _sub2a9c?.cancel();
      _sub2a9c = chr2a9c.lastValueStream.listen(_on2A9C, onError: (_) {});
      try { await chr2a9c.read(); } catch (_) {}
    }

    // --- subscribe 1530/1531 เป็น fallback ---
    for (final s in svcs) {
      for (final c in s.characteristics) {
        if (c.uuid == _chr1530 || c.uuid == _chr1531) {
          try { await c.setNotifyValue(true); } catch (_) {}
          _subs153x.add(c.lastValueStream.listen(_on153x, onError: (_) {}));
          try { await c.read(); } catch (_) {}
        }
      }
    }

    if (chr2a9c == null && _subs153x.isEmpty) {
      throw Exception('ไม่พบ 2A9C หรือ 1530/1531 บนอุปกรณ์นี้');
    }
    return _controller.stream;
  }

  /// บางเฟิร์มแวร์ต้องสั่งเริ่ม (optional)
  Future<void> requestMeasure() async {
    try {
      final svcs = await device.discoverServices();
      for (final s in svcs) {
        for (final c in s.characteristics) {
          if (c.uuid == _chr1532 && c.properties.write) {
            await c.write(const [0x01], withoutResponse: false);
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _sub2a9c?.cancel();
    for (final s in _subs153x) { await s.cancel(); }
    await _controller.close();
  }

  // ---------------- 2A9C parser (with weight fallback) ----------------
  void _on2A9C(List<int> data) {
    if (data.length < 2) return;

    int i = 0;
    final flags = data[i] | (data[i + 1] << 8);
    i += 2;

    final isSI            = (flags & 0x0001) == 0;  // 0=SI
    final hasTimestamp    = (flags & 0x0002) != 0;
    final hasUserId       = (flags & 0x0004) != 0;
    final hasBasalMet     = (flags & 0x0008) != 0;
    final hasMusclePct    = (flags & 0x0010) != 0;
    final hasMuscleMass   = (flags & 0x0020) != 0;
    final hasFatFreeMass  = (flags & 0x0040) != 0;
    final hasSoftLeanMass = (flags & 0x0080) != 0;
    final hasBodyWater    = (flags & 0x0100) != 0;
    final hasImpedance    = (flags & 0x0200) != 0;
    final hasWeight       = (flags & 0x0400) != 0;
    final hasHeight       = (flags & 0x0800) != 0;

    double? readSF() {
      if (data.length < i + 2) return null;
      final v = _decodeSfloat16(data[i], data[i + 1]);
      i += 2;
      return v;
    }

    if (hasTimestamp && data.length >= i + 7) i += 7;
    if (hasUserId    && data.length >= i + 1) i += 1;

    final out = <String, String>{};
    if (hasBasalMet)     { final v = readSF(); if (v != null) out['bmr_kcal'] = _fmt(v); }
    if (hasMusclePct)    { final v = readSF(); if (v != null) out['muscle_percent'] = _fmt(v); }
    if (hasMuscleMass)   { final v = readSF(); if (v != null) out['muscle_mass_kg'] = _fmt(v); }
    if (hasFatFreeMass)  { final v = readSF(); if (v != null) out['fat_free_mass_kg'] = _fmt(v); }
    if (hasSoftLeanMass) { final v = readSF(); if (v != null) out['soft_lean_mass_kg'] = _fmt(v); }
    if (hasBodyWater)    { final v = readSF(); if (v != null) out['body_water_kg'] = _fmt(v); }
    if (hasImpedance)    { final v = readSF(); if (v != null) out['impedance_ohm'] = _fmt(v); }

    // -- น้ำหนัก: ลอง SFLOAT ก่อน แล้ว fallback เป็น UInt16LE/200 ถ้าผิดปกติ --
    if (hasWeight && data.length >= i + 2) {
      final wIdx = i;
      double? w = readSF();
      bool ok = (w != null) && (w! >= 10.0) && (w! <= 300.0); // ช่วงสมเหตุผล
      if (!ok) {
        final raw = (data[wIdx] | (data[wIdx + 1] << 8)); // UInt16LE
        final guess = raw / 200.0;
        if (guess >= 10.0 && guess <= 300.0) {
          w = guess;
        }
      }
      if (w != null) {
        out[isSI ? 'weight_kg' : 'weight_lb'] = _fmt(w);
      }
    }

    // ส่วนสูง: ถ้าเจอค่าติดลบ/ผิดปกติจะไม่ใส่
    if (hasHeight && data.length >= i + 2) {
      final v = readSF();
      if (v != null && v > 0 && v < 3.0) {
        out[isSI ? 'height_m' : 'height_in'] = _fmt(v);
      }
    }

    // BMI คำนวณได้ถ้ามี w, h
    final w = double.tryParse(out['weight_kg'] ?? '');
    final h = double.tryParse(out['height_m'] ?? '');
    if (w != null && h != null && h > 0) {
      out['bmi'] = (w / (h * h)).toStringAsFixed(1);
    }

    if (out.isNotEmpty) {
      out['src'] = '2A9C';
      _controller.add(out);
    }
  }

  // --------------- Proprietary 1530/1531 fallback ---------------
  void _on153x(List<int> data) {
    String hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');

    // หา weight โดยลองทุก offset แบบ UInt16LE/200 แล้วเลือกค่าในช่วง 10–300 kg
    double? best;
    int? bestAt;
    for (int k = 0; k + 1 < data.length; k++) {
      final v = (data[k] | (data[k + 1] << 8)) / 200.0;
      if (v >= 10.0 && v <= 300.0) {
        best = v; bestAt = k; break; // พบคู่แรกที่สมเหตุผลก็พอ
      }
    }

    final out = <String, String>{
      'raw1530': hex(data),
      'src': '153x',
      if (best != null) 'weight_kg_guess': best!.toStringAsFixed(2),
      if (bestAt != null) 'guess_offset': bestAt.toString(),
    };
    _controller.add(out);
  }

  // --------------- helpers ---------------
  Future<void> _ensureConnected() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
    var st = await device.connectionState.first;
    if (st == BluetoothConnectionState.connected) return;
    if (st == BluetoothConnectionState.connecting) {
      st = await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 12), onTimeout: () => BluetoothConnectionState.disconnected);
      if (st == BluetoothConnectionState.connected) return;
    }
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
    await device.connectionState
        .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
        .first
        .timeout(const Duration(seconds: 12));
  }

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
}
