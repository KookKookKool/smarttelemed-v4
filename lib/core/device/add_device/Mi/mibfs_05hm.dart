// lib/core/device/add_device/Mi/mibfs_05hm.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

/// Xiaomi Mi Body Composition Scale (MIBFS / XMTZC05HM)
/// เปิดฟังทุกแชนเนล แล้ว "ยืนยันความเสถียร" ก่อนคอนเฟิร์มน้ำหนัก
class MiBfs05hm {
  MiBfs05hm({required this.device});
  final BluetoothDevice device;

  // Xiaomi private UUIDs
  static final Guid _chr1530 = Guid('00001530-0000-3512-2118-0009af100700');
  static final Guid _chr1531 = Guid('00001531-0000-3512-2118-0009af100700');
  static final Guid _chr1532 = Guid('00001532-0000-3512-2118-0009af100700'); // kickoff
  static final Guid _chr1542 = Guid('00001542-0000-3512-2118-0009af100700');
  static final Guid _chr1543 = Guid('00001543-0000-3512-2118-0009af100700');
  static final Guid _chr2A2Fv= Guid('00002a2f-0000-3512-2118-0009af100700');

  // BCS (บางล็อต)
  static final Guid _svc181B = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid _chr2A9C = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<Map<String, String>>.broadcast();
  final List<StreamSubscription<List<int>>> _subs = [];

  // สถานะภายใน
  String? _lockedSrc;        // ล็อกเฉพาะแชนเนลที่ยืนยันผลแล้ว
  double? _lastKg;           // ค่าสุดท้ายที่ส่งออกแล้ว
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  // ผู้สมัครก่อนยืนยัน
  double? _candKg;
  int _candStableCount = 0;
  DateTime? _candSince;

  // เกณฑ์เสถียร
  static const int _stableNeeded = 3;                 // ≥ 3 เฟรม
  static const Duration _stableWindow = Duration(milliseconds: 600); // รวม ≥ 600ms
  static const double _stableDeltaKg = 0.2;           // ±0.2 kg

  // ---------- public ----------
  Future<Stream<Map<String, String>>> parse() async {
    await _ensureConnected();
    final services = await device.discoverServices();

    // รวม candidates
    final candidates = <BluetoothCharacteristic>[];
    for (final s in services) {
      for (final c in s.characteristics) {
        final u = c.uuid;
        if (u == _chr1530 || u == _chr1531 || u == _chr1532 ||
            u == _chr1542 || u == _chr1543 || u == _chr2A2Fv ||
            (s.uuid == _svc181B && u == _chr2A9C)) {
          candidates.add(c);
        }
      }
    }
    if (candidates.isEmpty) {
      throw Exception('ไม่พบ characteristic สำหรับตาชั่ง (1530/1531/1532/1542/1543/2A2F/2A9C)');
    }

    // เปิด notify/subscribe ทุกตัว
    for (final c in candidates) {
      try { await c.setNotifyValue(true); } catch (_) {}
      _subs.add(c.lastValueStream.listen(
        (data) => _onFrame(data, srcUuid: c.uuid.str),
        onError: (_) {},
      ));
      try { await c.read(); } catch (_) {}
    }

    // kickoff: 1532 > 1530 > 1542 > 1543 > 1531 > 2A2F
    await _kickoff(services);
    return _controller.stream;
  }

  Future<void> dispose() async {
    for (final s in _subs) { await s.cancel(); }
    await _controller.close();
  }

  // ---------- internal ----------
  Future<void> _kickoff(List<BluetoothService> svcs) async {
    BluetoothCharacteristic? c1532, c1530, c1542, c1543, c1531, c2a2f;
    for (final s in svcs) {
      for (final c in s.characteristics) {
        if (c.uuid == _chr1532) c1532 = c;
        if (c.uuid == _chr1530) c1530 = c;
        if (c.uuid == _chr1542) c1542 = c;
        if (c.uuid == _chr1543) c1543 = c;
        if (c.uuid == _chr1531) c1531 = c;
        if (c.uuid == _chr2A2Fv) c2a2f = c;
      }
    }
    final order = [c1532, c1530, c1542, c1543, c1531, c2a2f]
        .where((c) => c != null && c!.properties.write)
        .cast<BluetoothCharacteristic>()
        .toList();

    for (final t in order) {
      try {
        await t.write(const [0x01], withoutResponse: false);
        await Future.delayed(const Duration(milliseconds: 120));
        try { await t.write(const [0x02], withoutResponse: false); } catch (_) {}
        break;
      } catch (_) {}
    }
  }

  void _resetCandidate() {
    _candKg = null;
    _candStableCount = 0;
    _candSince = null;
  }

  bool _isZeroishFrame(List<int> data) {
    if (data.length >= 13) {
      final lo = data[11] & 0xFF, hi = data[12] & 0xFF;
      if (lo == 0 && hi == 0) return true;     // 0.00 (LE/BE) บ่อยมากในตอนปล่อยเท้า
    }
    return false;
  }

  void _onFrame(List<int> data, {required String srcUuid}) {
    if (data.isEmpty) return;

    final sShort = _shortSrc(srcUuid);

    // ถ้าล็อก src แล้วและไม่ตรง → เมิน
    if (_lockedSrc != null && sShort != _lockedSrc) return;

    // ปลดล็อก/ล้างผู้สมัครเมื่อเจอเฟรมศูนย์ (ยกเท้าออก/รีเซ็ต)
    if (_isZeroishFrame(data)) {
      _lockedSrc = null;
      _resetCandidate();
      return;
    }

    // ดึงค่าน้ำหนักจากเฟรม (ยังไม่คอนเฟิร์ม)
    final kg = _extractWeightKg(data);
    if (kg == null) return;

    final now = DateTime.now();

    // --- สะสมความเสถียรของ "ผู้สมัคร" ---
    if (_candKg == null) {
      _candKg = kg;
      _candStableCount = 1;
      _candSince = now;
    } else {
      // ถ้าห่างนานเกินไป ให้เริ่มนับใหม่
      if (_candSince != null && now.difference(_candSince!).inMilliseconds > 1500) {
        _resetCandidate();
        _candKg = kg;
        _candStableCount = 1;
        _candSince = now;
      } else {
        if ((kg - _candKg!).abs() <= _stableDeltaKg) {
          _candStableCount += 1;
          // ขยับฐานเล็กน้อยเพื่อดูดซับ jitter
          _candKg = (_candKg! * 0.6) + (kg * 0.4);
        } else {
          // กระโดดไกล → เริ่มนับผู้สมัครใหม่
          _candKg = kg;
          _candStableCount = 1;
          _candSince = now;
        }
      }
    }

    // --- เงื่อนไข "ยืนยันผล" ก่อนส่งออก ---
    final longEnough = _candSince != null && now.difference(_candSince!) >= _stableWindow;
    if (_candStableCount >= _stableNeeded && longEnough) {
      final finalKg = _candKg!;
      // debounce ส่งซ้ำเร็วเกินไป
      if (_lastKg != null &&
          now.difference(_lastEmit).inMilliseconds < 150 &&
          (finalKg - _lastKg!).abs() < 0.05) {
        return;
      }

      _lockedSrc ??= sShort;   // ล็อกแชนเนลที่ยืนยันผลสำเร็จ
      _lastKg = finalKg;
      _lastEmit = now;

      _controller.add({
        'weight_kg': finalKg.toStringAsFixed(2),
        'src': sShort,
        'raw': _hex(data),
      });
    }
  }

  /// คืนค่าน้ำหนักแบบ heuristic:
  /// - ลอง offset 11..12 (LE/BE) ด้วย divisor 200 หรือ 100
  /// - แล้วจึง slide ทุก offset หา UInt16 (LE/BE) ด้วย divisor 200/100
  double? _extractWeightKg(List<int> data) {
    // 1) offset 11..12 บ่อยสุด
    if (data.length >= 13) {
      final lo = data[11] & 0xFF;
      final hi = data[12] & 0xFF;
      final le = (lo | (hi << 8));
      final be = ((lo << 8) | hi);
      for (final d in const [200, 100]) {
        final w1 = le / d; if (_isValidKg(w1)) return w1;
        final w2 = be / d; if (_isValidKg(w2)) return w2;
      }
    }
    // 2) สไลด์ทุก offset
    for (int i = 0; i + 1 < data.length; i++) {
      final lo = data[i] & 0xFF, hi = data[i + 1] & 0xFF;
      final le = (lo | (hi << 8));
      final be = ((lo << 8) | hi);
      for (final d in const [200, 100]) {
        final w1 = le / d; if (_isValidKg(w1)) return w1;
        final w2 = be / d; if (_isValidKg(w2)) return w2;
      }
    }
    return null;
  }

  bool _isValidKg(double v) => v >= 10.0 && v <= 300.0;

  String _shortSrc(String u) {
    final s = u.toLowerCase();
    if (s.contains('00001530')) return '1530';
    if (s.contains('00001531')) return '1531';
    if (s.contains('00001532')) return '1532';
    if (s.contains('00001542')) return '1542';
    if (s.contains('00001543')) return '1543';
    if (s.contains('00002a2f')) return '2A2Fv';
    if (s.contains('00002a9c')) return '2A9C';
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
          .where((s) =>
              s == BluetoothConnectionState.connected ||
              s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 12),
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
