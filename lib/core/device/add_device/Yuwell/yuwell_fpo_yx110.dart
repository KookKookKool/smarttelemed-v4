// 📂 lib/core/device/yuwell_fpo_yx110.dart
import 'dart:async';
import 'dart:collection';
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

  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();

    final services = await device.discoverServices();

    // หา service/char แบบยืดหยุ่น (ทั้ง uuid ตรง และลงท้าย)
    BluetoothCharacteristic? target;
    for (final s in services) {
      final su = s.uuid.str.toLowerCase();
      final isMatchSvc = (s.uuid == _svcFfe0) || su.endsWith('ffe0');
      if (!isMatchSvc) continue;

      for (final c in s.characteristics) {
        final cu = c.uuid.str.toLowerCase();
        final isMatchChr = (c.uuid == _chrFfe4) || cu.endsWith('ffe4');
        if (isMatchChr) {
          target = c;
          break;
        }
      }
      if (target != null) break;
    }

    if (target == null) {
      throw Exception('ไม่พบ FFE0/FFE4 (Yuwell oximeter) ใน services ของอุปกรณ์นี้');
    }

    // เปิด notify
    try {
      await target.setNotifyValue(true);
    } catch (e) {
      // บางรุ่นจะ error ถ้าไม่มี notify/indicate flag — ให้แค่ log แล้วไปต่อ
      // debugPrint('setNotifyValue error: $e');
    }

    // สมัครสองสตรีม (เวอร์ชัน lib บางตัวให้ค่าจาก onValueReceived เร็วกว่าหรืออย่างเดียว)
    await _subA?.cancel();
    await _subB?.cancel();

    _subA = target.onValueReceived.listen(_onFrame, onError: (e) {});
    _subB = target.lastValueStream.listen(_onFrame, onError: (e) {});

    // wake up (บางรุ่นต้อง read หนแรก)
    try {
      await target.read();
    } catch (_) {}

    return _controller.stream;
  }

  void _onFrame(List<int> values) {
    if (values.isEmpty) return;

    // print raw hex ช่วยดีบัก
    // print('YX110 raw: ${_hex(values)}');

    final out = _parseYuwell(values);
    if (out != null) {
      _controller.add(out);
    }
  }

  /// พาร์สสองรูปแบบ:
  /// A) รูปแบบที่พบมากใน Yuwell: PR=values[4], SpO2=values[5]
  /// B) fallback: หา SpO2 (70..100) และ PR (30..250) แบบเดาอย่างปลอดภัย
  Map<String, String>? _parseYuwell(List<int> v) {
    // รูปแบบ A (เดิมของคุณ)
    if (v.length > 5) {
      final pr = v[4];
      final spo2 = v[5];
      if (_validPr(pr) && _validSpo2(spo2)) {
        return {
          'spo2': spo2.toString(),
          'pr': pr.toString(),
          'raw': _hex(v),
          'ts': DateTime.now().toIso8601String(),
        };
      }
    }

    // รูปแบบ B (fallback เดา)
    int? pr, spo2;

    // เดา SpO2: หา value 70..100 ที่ใกล้ index 5 ก่อน
    for (final idx in [5, 4, 6, 3, 7, 2, 8, 1, 9, 0]) {
      if (idx < v.length && _validSpo2(v[idx])) {
        spo2 = v[idx];
        break;
      }
    }

    // เดา PR: หา 30..250 (8-bit หรือคู่ bytes แบบ 16-bit เล็ก)
    for (final idx in [4, 3, 5, 2, 6, 1, 7, 0]) {
      if (idx < v.length && _validPr(v[idx])) {
        pr = v[idx];
        break;
      }
    }
    // ลองอ่านเป็น 16-bit LE ด้วย ถ้าค่า 8-bit ไม่เข้าเกณฑ์
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
      return {'pr': '$pr', 'spo2': '$spo2', 'raw': _hex(v)};
    }

    // ถ้ายังตีไม่ได้ ก็ไม่ส่ง เพื่อไม่ให้ UI ขึ้นค่าผิด
    return null;
  }

  bool _validSpo2(int x) => x >= 70 && x <= 100;
  bool _validPr(int x) => x >= 30 && x <= 250;

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> dispose() async {
    await _subA?.cancel();
    await _subB?.cancel();
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