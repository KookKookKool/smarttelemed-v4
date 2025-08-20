// lib/core/device/add_device/jumper_po_jpd_500f.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';


/// Jumper Oximeter (My Oximeter) — อ่าน "เฉพาะ" Characteristic CDEACB81 เท่านั้น
/// และ "ล็อก" ให้รับเฉพาะเฟรมที่ขึ้นต้นด้วย 0x81
/// รูปแบบเฟรม: 81 PR SpO2 XX
/// ตัวอย่าง: 81 38 63 44  -> PR=0x38(56), SpO2=0x63(99)
/// ส่งออก: { spo2: '99', pr: '56', raw: '81 38 63 44', src: 'cde:idx(PR0,SpO21)' }
class JumperPoJpd500f {
  JumperPoJpd500f({required this.device});
  final BluetoothDevice device;

  // อ่าน "เฉพาะ" Char นี้
  static final Guid _chrCde81 = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _sub;

  int? _lastSpo2, _lastPr;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// สมัคร notify เฉพาะ characteristic cdeacb81 (ไม่สนว่าอยู่ใน service ไหน)
  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();

    // ค้นหา characteristic cdeacb81 จากทุก service
    final services = await device.discoverServices();
    final chr = _findChrCde81(services);

    if (chr == null) {
      throw Exception('ไม่พบ Characteristic CDEACB81 บนอุปกรณ์นี้');
    }

    try { await chr.setNotifyValue(true); } catch (_) {}
    await _sub?.cancel();
    _sub = chr.lastValueStream.listen(_onCde81Frame, onError: (_) {});
    try { await chr.read(); } catch (_) {}

    return _controller.stream;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  // ------------ Handler: เฉพาะ CDEACB81 ------------
  void _onCde81Frame(List<int> frame) {
    // ต้องมี header 0x81 เท่านั้น และยาว >= 3 (81 PR SpO2 ...)
    if (frame.length < 3) return;
    if (frame[0] != 0x81) return; // <<< ล็อกเฉพาะ 0x81 ไม่รับ 0x80 อีกต่อไป

    final pr   = frame[1] & 0xFF;   // หลัง header: PR = byte[1]
    final spo2 = frame[2] & 0xFF;   // หลัง header: SpO2 = byte[2]

    // กันค่า placeholder/ผิดปกติทั่วไป
    if (!_okP(pr) || !_okS(spo2)) return;

    // กันสแปม/ซ้ำถี่เกิน
    final now = DateTime.now();
    if (_lastSpo2 == spo2 && _lastPr == pr &&
        now.difference(_lastEmit).inMilliseconds < 120) {
      return;
    }
    _lastSpo2 = spo2; _lastPr = pr; _lastEmit = now;

    _controller.add({
      'spo2': '$spo2',
      'pr'  : '$pr',
      'raw' : _hex(frame),
      'src' : 'cde:idx(PR0,SpO21)',   // ค่าคงที่ตามที่กำหนด
    });
  }

  // ------------ ค้นหา CDEACB81 จากทุก service ------------
  BluetoothCharacteristic? _findChrCde81(List<BluetoothService> services) {
    // หาแบบเป๊ะก่อน
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid == _chrCde81) return c;
      }
    }
    // เผื่อ UUID แปลก: match ลงท้าย cb81
    for (final s in services) {
      for (final c in s.characteristics) {
        final u = c.uuid.str.toLowerCase();
        if (u.endsWith('cb81')) return c;
      }
    }
    return null;
  }

  // ------------ BLE helpers ------------
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

  // ------------ Utils ------------
  bool _okS(int x) => x >= 70 && x <= 100;   // ช่วง SpO2 ที่สมเหตุผล
  bool _okP(int x) => x >= 30 && x <= 250;   // ช่วง PR ที่สมเหตุผล

  String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join(' ');
}