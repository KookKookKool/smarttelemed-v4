// lib/core/device/add_device/mibfs_05hm.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Xiaomi Mi Body Composition Scale (MIBFS / XMTZC05HM)
/// ✅ โฟกัสเฉพาะ "น้ำหนัก" เท่านั้น
/// - ฟัง notify: 0x1530 / 0x1531 / 0x1542 / 0x1543 / 0x2A2F(เวนเดอร์)
/// - เริ่มวัด: write 0x01 (และลอง 0x02) ไปที่ 0x1532
/// - ถอดน้ำหนัก: ค้นหา UInt16LE / 200.0 ที่ได้ค่าอยู่ช่วง 10–300 kg
///
/// ส่งออก Stream<Map<String,String>>:
/// { weight_kg: "72.35", src: "1530", raw: "..." }
class MiBfs05hm {
  MiBfs05hm({required this.device});
  final BluetoothDevice device;

  // Xiaomi private UUIDs (ตามหน้าจอที่แนบมา)
  static final Guid _chr1530 = Guid('00001530-0000-3512-2118-0009af100700'); // notify, write
  static final Guid _chr1531 = Guid('00001531-0000-3512-2118-0009af100700'); // notify, write
  static final Guid _chr1532 = Guid('00001532-0000-3512-2118-0009af100700'); // write (kickoff)
  static final Guid _chr1542 = Guid('00001542-0000-3512-2118-0009af100700'); // notify, read, write
  static final Guid _chr1543 = Guid('00001543-0000-3512-2118-0009af100700'); // notify, read, write
  static final Guid _chr2A2FVendor = Guid('00002a2f-0000-3512-2118-0009af100700'); // notify, write (เวนเดอร์)

  final _controller = StreamController<Map<String, String>>.broadcast();
  final List<StreamSubscription<List<int>>> _subs = [];

  // กันสแปม/เด้งรัว
  double? _lastKg;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  // ---------- public ----------
  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();
    final services = await device.discoverServices();

    // เปิด notify เฉพาะ characteristic ที่เกี่ยวกับน้ำหนัก (เอกชน Xiaomi)
    final listenThese = <BluetoothCharacteristic>[];
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid == _chr1530 ||
            c.uuid == _chr1531 ||
            c.uuid == _chr1542 ||
            c.uuid == _chr1543 ||
            c.uuid == _chr2A2FVendor) {
          listenThese.add(c);
        }
      }
    }

    for (final c in listenThese) {
      try { await c.setNotifyValue(true); } catch (_) {}
      _subs.add(c.lastValueStream.listen(
        (data) => _onWeightFrame(data, srcUuid: c.uuid.str),
        onError: (_) {},
      ));
      try { await c.read(); } catch (_) {}
    }

    // เขียน kickoff เริ่มวัด (ถ้ามี 1532)
    await _kickoff(services);

    if (_subs.isEmpty) {
      throw Exception('ไม่พบ characteristic ที่ใช้ชั่งน้ำหนัก (1530/1531/1542/1543/2A2F-vendor)');
    }

    return _controller.stream;
  }

  Future<void> dispose() async {
    for (final s in _subs) { await s.cancel(); }
    await _controller.close();
  }

  // ---------- internal ----------
  Future<void> _kickoff(List<BluetoothService> svcs) async {
    try {
      for (final s in svcs) {
        for (final c in s.characteristics) {
          if (c.uuid == _chr1532 && c.properties.write) {
            await c.write(const [0x01], withoutResponse: false);
            await Future.delayed(const Duration(milliseconds: 120));
            // บางล็อตต้องตามด้วย 0x02
            try { await c.write(const [0x02], withoutResponse: false); } catch (_) {}
            return;
          }
        }
      }
    } catch (_) {}
  }

  void _onWeightFrame(List<int> data, {required String srcUuid}) {
    if (data.isEmpty) return;

    // 1) ตำแหน่งยอดนิยม: [11..12] / 200.0
    double? kg;
    if (data.length >= 13) {
      final w = ((data[11] & 0xFF) | ((data[12] & 0xFF) << 8)) / 200.0;
      if (_isValidKg(w)) kg = w;
    }

    // 2) ถ้ายังไม่เจอ ลองสไลด์ทุก offset (UInt16LE / 200.0)
    kg ??= _scanUInt16Div200(data);

    if (kg == null) return;

    // ลดเด้งซ้ำภายใน 150ms และต่างจากเดิมเล็กน้อย
    final now = DateTime.now();
    if (_lastKg != null &&
        now.difference(_lastEmit).inMilliseconds < 150 &&
        (kg - _lastKg!).abs() < 0.05) {
      return;
    }
    _lastKg = kg;
    _lastEmit = now;

    _controller.add({
      'weight_kg': kg.toStringAsFixed(2),
      'src': _shortSrc(srcUuid),
      'raw': _hex(data),
    });
  }

  bool _isValidKg(double v) => v >= 10.0 && v <= 300.0;

  double? _scanUInt16Div200(List<int> data) {
    for (int i = 0; i + 1 < data.length; i++) {
      final w = ((data[i] & 0xFF) | ((data[i + 1] & 0xFF) << 8)) / 200.0;
      if (_isValidKg(w)) return w;
    }
    return null;
  }

  String _shortSrc(String u) {
    final s = u.toLowerCase();
    if (s.contains('00001530')) return '1530';
    if (s.contains('00001531')) return '1531';
    if (s.contains('00001532')) return '1532';
    if (s.contains('00001542')) return '1542';
    if (s.contains('00001543')) return '1543';
    if (s.contains('00002a2f')) return '2A2Fv';
    return u;
  }

  String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join(' ');

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
}
