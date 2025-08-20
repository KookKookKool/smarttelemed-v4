// lib/core/device/add_device/Jumper/jumper_jpd_ha120.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Jumper JPD-HA120 (Blood Pressure)
/// Frame: FD FD FC <SYS> <DIA> <PULSE> [0D 0A]
/// Example: fd fd fc 63 39 43 0d 0a -> SYS=99, DIA=57, PUL=67
class JumperJpdHa120 {
  JumperJpdHa120({required this.device});
  final BluetoothDevice device;

  static final Guid _svcFff0 = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFff1 = Guid('0000fff1-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid _chrFff2 = Guid('0000fff2-0000-1000-8000-00805f9b34fb'); // write/wwr
  

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _sub;

  // กันสแปม
  int? _lastSys, _lastDia, _lastPul;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Stream<Map<String, String>>> parse() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}

    var st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 12));
    }

    final services = await device.discoverServices();

    // หา target = FFF1 (ถ้าไม่เจอ fallback เป็นตัวที่ notify ได้ภายใต้ FFF0)
    BluetoothCharacteristic? target = _findChar(services, _chrFff1);
    target ??= _findFirstNotifyInService(services, _svcFff0);

    if (target == null) {
      throw Exception('JPD-HA120: ไม่พบ characteristic ที่อ่านค่าได้ใน Service FFF0');
    }

    try { await target.setNotifyValue(true); } catch (_) {}
    await _sub?.cancel();
    _sub = target.lastValueStream.listen((d) => _onFrame(target!.uuid, d), onError: (_) {});
    try { await target.read(); } catch (_) {}

    // ปลุกอุปกรณ์ (ถ้ามี fff2 และอนุญาต write/wwr)
    final fff2 = _findChar(services, _chrFff2);
    if (fff2 != null && (fff2.properties.write || fff2.properties.writeWithoutResponse)) {
      try { await fff2.write(const [0x01], withoutResponse: true); } catch (_) {}
    }

    return _controller.stream;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  // ----------------- parser -----------------
  void _onFrame(Guid fromChr, List<int> data) {
    if (data.length < 6) {
      _emitRaw(fromChr, data);
      return;
    }

    // สแกนหา header FD FD FC ภายใน buffer
    for (int i = 0; i + 5 < data.length; i++) {
      if (data[i] == 0xFD && data[i + 1] == 0xFD && data[i + 2] == 0xFC) {
        final sys = data[i + 3];
        final dia = data[i + 4];
        final pul = data[i + 5];

        if (_ok(sys, 60, 260) && _ok(dia, 30, 200) && _ok(pul, 30, 250)) {
          // กันสแปมซ้ำถี่เกิน 120ms และค่าซ้ำเดิมทั้งหมด
          final now = DateTime.now();
          if (_lastSys == sys && _lastDia == dia && _lastPul == pul &&
              now.difference(_lastEmit).inMilliseconds < 120) {
            return;
          }
          _lastSys = sys; _lastDia = dia; _lastPul = pul; _lastEmit = now;

          final map = (dia + ((sys - dia) / 3)).round();
          _controller.add({
            'sys': '$sys',
            'dia': '$dia',
            // 'map': '$map',
            'pul': '$pul',
            'raw': _hex(data),
            'src': 'ha120:${fromChr.str.toLowerCase()}',
          });
          return; // จบที่เฟรมแรกที่เจอ
        }
      }
    }

    // ไม่เข้าเงื่อนไข → ส่งค่า raw ไว้ debug
    _emitRaw(fromChr, data);
  }

  // ----------------- helpers -----------------
  BluetoothCharacteristic? _findChar(List<BluetoothService> svcs, Guid uuid) {
    for (final s in svcs) {
      for (final c in s.characteristics) {
        if (c.uuid == uuid) return c;
      }
    }
    return null;
  }

  BluetoothCharacteristic? _findFirstNotifyInService(List<BluetoothService> svcs, Guid svcUuid) {
    for (final s in svcs) {
      if (s.uuid == svcUuid || s.uuid.str.toLowerCase().endsWith('fff0')) {
        for (final c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) return c;
        }
      }
    }
    return null;
  }

  void _emitRaw(Guid fromChr, List<int> data) {
    _controller.add({
      'raw': _hex(data),
      'src': 'ha120:${fromChr.str.toLowerCase()}',
    });
  }

  bool _ok(int v, int lo, int hi) => v >= lo && v <= hi;

  String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join(' ');
}