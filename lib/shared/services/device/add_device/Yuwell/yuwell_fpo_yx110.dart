// 📂 lib/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart
//
// Yuwell FPO/YX110 — Oximeter เท่านั้น
// - ปล่อยเฉพาะคีย์: spo2, pr, raw, ts, src
// - ❌ ไม่ส่ง temp/temp_c/temperature เด็ดขาด
// - มี dedup เฟรมซ้ำด้วย _lastHex

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

class YuwellFpoYx110 {
  YuwellFpoYx110({required this.device});

  final BluetoothDevice device;

  static final Guid _svcFfe0 = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFfe4 = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _subA;
  StreamSubscription<List<int>>? _subB;

  String? _lastHex;
  DateTime? _lastEmitAt;
  bool _disposed = false;

  /// คืน Stream<Map<String,String>> ผ่าน Future (ให้เข้ากับโค้ดที่ `await .parse()`)
  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();

    final services = await device.discoverServices();

    // หา FFE0/FFE4 แบบยืดหยุ่น (เท่ากันเป๊ะ หรือ UUID ลงท้าย)
    BluetoothCharacteristic? target;
    for (final s in services) {
      final su = s.uuid.str.toLowerCase();
      final matchSvc = (s.uuid == _svcFfe0) || su.endsWith('ffe0');
      if (!matchSvc) continue;

      for (final c in s.characteristics) {
        final cu = c.uuid.str.toLowerCase();
        final matchChr = (c.uuid == _chrFfe4) || cu.endsWith('ffe4');
        if (matchChr) {
          target = c;
          break;
        }
      }
      if (target != null) break;
    }

    if (target == null) {
      throw Exception('ไม่พบ FFE0/FFE4 (Yuwell oximeter) ใน services ของอุปกรณ์นี้');
    }

    // เปิด notify (บางรุ่นจะไม่มี flag → try/catch ไว้)
    try {
      await target.setNotifyValue(true);
    } catch (_) {}

    // สมัครสองสตรีม (รองรับพฤติกรรม lib ต่างเวอร์ชัน)
    await _subA?.cancel();
    await _subB?.cancel();

    _subA = target.onValueReceived.listen(_onFrame, onError: (_) {});
    _subB = target.lastValueStream.listen(_onFrame, onError: (_) {});

    // Wake up: บางรุ่นต้อง read หนึ่งครั้ง
    try {
      await target.read();
    } catch (_) {}

    return _controller.stream;
  }

  void _onFrame(List<int> values) {
    if (_disposed || values.isEmpty) return;

    // dedup เฟรมซ้ำถี่ ๆ
    final hex = _hex(values);
    final now = DateTime.now();
    if (_lastHex == hex && _lastEmitAt != null) {
      final dt = now.difference(_lastEmitAt!);
      if (dt.inMilliseconds < 250) return; // ข้ามเฟรมซ้ำในช่วงสั้น ๆ
    }

    final parsed = _parseYuwell(values);
    if (parsed != null) {
      _lastHex = hex;
      _lastEmitAt = now;

      // ✅ ปล่อยเฉพาะ spo2/pr เท่านั้น (ห้ามหลุด temp/temp_c/temperature)
      final out = <String, String>{};
      if (parsed['spo2'] != null) out['spo2'] = parsed['spo2']!;
      if (parsed['pr'] != null) out['pr'] = parsed['pr']!;

      // ถ้าพาร์สได้ไม่ครบ (เช่นได้อย่างใดอย่างหนึ่ง) ให้ข้าม เพื่อกัน UI แสดงค่าเพี้ยน
      if (out.length < 2) return;

      // เมทาดาต้า
      out['src'] = 'yx110';
      out['ts']  = now.toIso8601String();
      out['raw'] = hex;

      _controller.add(out);
    }
  }

  /// พาร์ส 2 แบบ:
  /// A) รูปแบบที่เจอบ่อยของ Yuwell: PR = v[4], SpO2 = v[5]
  /// B) Fallback: เดาค่าที่มีช่วงสมเหตุสมผล (SpO2: 70..100, PR: 30..250)
  Map<String, String>? _parseYuwell(List<int> v) {
    // --- รูปแบบ A ---
    if (v.length > 5) {
      final pr = v[4];
      final spo2 = v[5];
      if (_validPr(pr) && _validSpo2(spo2)) {
        return {'spo2': '$spo2', 'pr': '$pr'};
      }
    }

    // --- รูปแบบ B (fallback) ---
    int? spo2, pr;

    // หา SpO2 ที่ index ใกล้ ๆ 5 ก่อน
    for (final idx in [5, 4, 6, 3, 7, 2, 8, 1, 9, 0]) {
      if (idx < v.length && _validSpo2(v[idx])) {
        spo2 = v[idx];
        break;
      }
    }

    // หา PR แบบ 8-bit ก่อน
    for (final idx in [4, 3, 5, 2, 6, 1, 7, 0]) {
      if (idx < v.length && _validPr(v[idx])) {
        pr = v[idx];
        break;
      }
    }

    // ถ้า 8-bit ไม่เข้าเกณฑ์ ลองอ่านแบบ 16-bit little-endian
    if (pr == null && v.length >= 3) {
      for (int i = 1; i + 1 < v.length; i++) {
        final x = v[i] | (v[i + 1] << 8);
        if (x >= 30 && x <= 250) {
          pr = x;
          break;
        }
      }
    }

    if (spo2 != null && pr != null) {
      return {'spo2': '$spo2', 'pr': '$pr'};
    }

    // ตีความไม่ได้ → ไม่ส่ง (กัน UI แสดงค่าผิด)
    return null;
  }

  bool _validSpo2(int x) => x >= 70 && x <= 100;
  bool _validPr(int x) => x >= 30 && x <= 250;

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> dispose() async {
    _disposed = true;
    try { await _subA?.cancel(); } catch (_) {}
    try { await _subB?.cancel(); } catch (_) {}
    await _controller.close();
  }

  // ให้แน่ใจว่ายัง connected และหยุด scan กันชน
  Future<void> _ensureConnected() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
    var st = await device.connectionState.first;
    if (st == BluetoothConnectionState.connected) return;

    if (st == BluetoothConnectionState.connecting) {
      st = await device.connectionState
          .where((s) =>
              s == BluetoothConnectionState.connected ||
              s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 10),
              onTimeout: () => BluetoothConnectionState.disconnected);
      if (st == BluetoothConnectionState.connected) return;
    }

    await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
    await device.connectionState
        .where((s) =>
            s == BluetoothConnectionState.connected ||
            s == BluetoothConnectionState.disconnected)
        .first
        .timeout(const Duration(seconds: 12));
  }
}
