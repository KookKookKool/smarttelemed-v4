// lib/core/device/add_device/Jumper/jumper_jpd_fr400.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class JumperFr400 {
  JumperFr400({required this.device});
  final BluetoothDevice device;

  static final Guid _svcFff0 = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFff2 = Guid('0000fff2-0000-1000-8000-00805f9b34fb'); // write? (kick)

  // Stream อุณหภูมิ (°C)
  final _tempCtrl = StreamController<double>.broadcast();
  Stream<double> get onTemperature => _tempCtrl.stream;

  // Stream แบบ Map สำหรับต่อกับ _ParserBinding.map
  Stream<Map<String, String>> get parse {
    _ensureStarted();
    return onTemperature.map((t) => {
      'temp': t.toStringAsFixed(2),
      if (_lastRawHex != null) 'raw': _lastRawHex!,
      if (_lastSrc != null)    'src': _lastSrc!,
    });
  }

  final List<BluetoothCharacteristic> _notifChars = [];
  final List<StreamSubscription> _subs = [];
  BluetoothCharacteristic? _kickChar;
  String? _lastRawHex, _lastSrc;

  bool _starting = false, _started = false, _kicked = false;

  void _ensureStarted() {
    if (_started || _starting) return;
    _starting = true;
    // ignore: discarded_futures
    start().whenComplete(() { _starting = false; _started = true; });
  }

  Future<void> start() async {
    // connect
    var st = await device.connectionState.first;
    if (st == BluetoothConnectionState.disconnected) {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 8));
      st = await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 8));
      if (st != BluetoothConnectionState.connected) {
        throw 'FR400: connect failed';
      }
    }

    // discover
    final svcs = await device.discoverServices();

    // เก็บทุก char ที่ notify/indicate จากทุก service (ไม่หยุดที่ service แรก)
    _notifChars.clear();
    _kickChar = null;
    for (final s in svcs) {
      for (final c in s.characteristics) {
        if (c.properties.notify || c.properties.indicate) {
          _notifChars.add(c);
        }
        if (s.uuid == _svcFff0 && c.uuid == _chrFff2 && c.properties.write) {
          _kickChar ??= c;
        }
      }
    }
    if (_notifChars.isEmpty) {
      // เผื่อสุดทาง เลือก char แรกจาก FFF0 ถ้ามี
      final fff0 = svcs.where((s) => s.uuid == _svcFff0);
      if (fff0.isNotEmpty && fff0.first.characteristics.isNotEmpty) {
        _notifChars.add(fff0.first.characteristics.first);
      }
    }
    if (_notifChars.isEmpty) {
      throw StateError('FR400: no suitable characteristic to subscribe');
    }

    // subscribe ทั้งสองทาง + read หนึ่งครั้ง
    for (final c in _notifChars) {
      try { await c.setNotifyValue(true); } catch (_) {}
      _subs.add(c.onValueReceived.listen(_onBytes, onError: (e) {
        debugPrint('[FR400] onValueReceived error: $e');
      }));
      _subs.add(c.lastValueStream.listen(_onBytes, onError: (e) {
        debugPrint('[FR400] lastValueStream error: $e');
      }));
      try { await c.read(); } catch (_) {}
    }

    // ถ้า 1 วินาทียังไม่เห็นค่า และมี kick ได้ ให้ลองเขี่ยเบา ๆ
    Future.delayed(const Duration(seconds: 1), () async {
      if (_tempGot || _kicked || _kickChar == null) return;
      try {
        _kicked = true;
        await _kickChar!.write(const [0x01], withoutResponse: true);
      } catch (_) {}
    });
  }

  bool _tempGot = false;

  void _onBytes(List<int> data) {
    if (data.isEmpty) return;

    _lastRawHex = _hex(data);
    // หา source แบบคร่าว ๆ (ไม่ได้พก source ใน callback; เก็บตัวสุดท้ายที่ setNotify ช่วยไม่ได้มากนัก)
    // ผู้ใช้จะเห็น raw hex บน UI ได้ถ้า map ผ่าน parse
    final t = _tryParseTemp(data);
    if (t == null) return;

    if (t < 30 || t > 44) return; // กรองช่วงมนุษย์
    _tempGot = true;
    _tempCtrl.add(t);
  }

  // เดาค่า temp จากหลายโครงสร้างเฟรม
  double? _tryParseTemp(List<int> b) {
    // 1) FD FD ?? <hi> <lo> 0D 0A  -> (hi<<8|lo)/10
    if (b.length >= 6 && b[0] == 0xFD && b[1] == 0xFD) {
      final raw = (b[3] << 8) | b[4];
      final v = raw / 10.0;
      if (v > 25 && v < 45) return v;
      if (v >= 90 && v <= 113) return (v - 32.0) / 1.8;
    }

    // 2) ASCII เช่น "36.7", "T=36.5C", "98.6F"
    try {
      final s = String.fromCharCodes(b);
      final m = RegExp(r'(-?\d{2}\.\d{1,2})').firstMatch(s);
      if (m != null) {
        final v = double.parse(m.group(0)!);
        if (s.contains('F') && !s.contains('C')) return (v - 32.0) / 1.8;
        return v;
      }
    } catch (_) {}

    // 3) sweep 16-bit /10 และ /100
    for (int i = 0; i + 1 < b.length; i++) {
      final raw = (b[i] << 8) | b[i + 1];
      final v10 = raw / 10.0;
      final v100 = raw / 100.0;
      if (v10 >= 30 && v10 <= 44) return v10;
      if (v10 >= 90 && v10 <= 113) return (v10 - 32.0) / 1.8;
      if (v100 >= 30 && v100 <= 44) return v100;
    }

    return null;
  }

  String _hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> stop() async {
    for (final s in _subs) { try { await s.cancel(); } catch (_) {} }
    _subs.clear();
    for (final c in _notifChars) {
      try { if (c.isNotifying) await c.setNotifyValue(false); } catch (_) {}
    }
    _notifChars.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _tempCtrl.close();
  }
}
