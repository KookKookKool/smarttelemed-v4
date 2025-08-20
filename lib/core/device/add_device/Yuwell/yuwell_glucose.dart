// lib/core/device/yuwell_glucose.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus; // <- import หลัก (BluetoothDevice/Guid/..)
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp show FlutterBluePlusException; // <- เอาไว้จับ exception เฉพาะ
/// อ่านค่า Glucose ผ่าน Glucose Service (0x1808)
/// - Measurement (0x2A18) → Notify
/// - RACP (0x2A52) → Indicate + Write (ดึงประวัติ)
/// ส่งออก Stream<Map<String,String>>
class YuwellGlucose {
  YuwellGlucose({required this.device});
  final BluetoothDevice device;

  // UUIDs
  static final Guid _svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid _chrMeas    = Guid('00002a18-0000-1000-8000-00805f9b34fb'); // Notify
  static final Guid _chrContext = Guid('00002a34-0000-1000-8000-00805f9b34fb'); // Notify (optional)
  static final Guid _chrFeature = Guid('00002a51-0000-1000-8000-00805f9b34fb'); // Read (optional)
  static final Guid _chrRacp    = Guid('00002a52-0000-1000-8000-00805f9b34fb'); // Indicate + Write

  // Current Time (บางรุ่นต้องตั้งเวลาก่อน)
  static final Guid _svcTime    = Guid('00001805-0000-1000-8000-00805f9b34fb');
  static final Guid _chrCurTime = Guid('00002a2b-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<Map<String, String>>.broadcast();
  StreamSubscription<List<int>>? _subMeas;
  StreamSubscription<List<int>>? _subRacp;

  Future<Stream<Map<String, String>>> parse({
    bool fetchLastOnly = true,
    bool syncTime = false,
  }) async {
    // ensure connected + ขอ MTU + (Android) bond (ลดโอกาส error:13)
    if (await device.connectionState.first != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 10));
    }
    try { await device.requestMtu(247); } catch (_) {}
    if (Platform.isAndroid) {
      try { await device.createBond(); } catch (_) {}
    }

    // discover
    final services = await device.discoverServices();
    final svcG = services.firstWhere(
      (s) => s.uuid == _svcGlucose,
      orElse: () => throw Exception('ไม่พบ Glucose Service (0x1808)'),
    );
    final chrMeas = svcG.characteristics.firstWhere(
      (c) => c.uuid == _chrMeas,
      orElse: () => throw Exception('ไม่พบ Glucose Measurement (0x2A18)'),
    );
    final chrRacp = svcG.characteristics.firstWhere(
      (c) => c.uuid == _chrRacp,
      orElse: () => throw Exception('ไม่พบ RACP (0x2A52)'),
    );
    final BluetoothCharacteristic? chrContext =
        svcG.characteristics.where((c) => c.uuid == _chrContext).firstOrNull;

    // (optional) sync time
    if (syncTime) {
      final svcT = services.where((s) => s.uuid == _svcTime).firstOrNull;
      final chrCT = svcT?.characteristics.where((c) => c.uuid == _chrCurTime).firstOrNull;
      if (chrCT != null && (chrCT.properties.write || chrCT.properties.writeWithoutResponse)) {
        await _writeCurrentTime(chrCT);
      }
    }

    // enable notify/indicate
    await chrMeas.setNotifyValue(true);
    await chrRacp.setNotifyValue(true);
    if (chrContext != null) { try { await chrContext.setNotifyValue(true); } catch (_) {} }

    // ให้ CCCD เซ็ตเสร็จก่อนค่อยเขียน RACP (สำคัญกับ Android)
    await Future.delayed(const Duration(milliseconds: 400));

    // listeners
    await _subMeas?.cancel();
    _subMeas = chrMeas.lastValueStream.listen((data) {
      final out = _parseGlucoseMeasurement(data);
      if (out != null) _controller.add({...out, 'src': 'yuwell_glucose'});
    });

    await _subRacp?.cancel();
    _subRacp = chrRacp.lastValueStream.listen((d) {
      if (d.isNotEmpty) _controller.add({'racp': _hex(d)});
    });

    // helper: รอ indication ครั้งถัดไปของ RACP
    Future<List<int>> _awaitRacpOnce({Duration timeout = const Duration(seconds: 3)}) async {
      final c = Completer<List<int>>();
      StreamSubscription<List<int>>? tmp;
      tmp = chrRacp.lastValueStream.listen((d) {
        if (!c.isCompleted) c.complete(d);
        tmp?.cancel();
      });
      try { return await c.future.timeout(timeout, onTimeout: () => <int>[]); }
      finally { await tmp?.cancel(); }
    }

    // ========= แกนสำคัญ: safe write แก้ error 13 =========
    Future<void> _safeWrite(List<int> v) async {
  // ถ้า char เขียนได้แค่ no-response ก็ใช้แบบนั้นก่อน
      final preferNoResp = !chrRacp.properties.write && chrRacp.properties.writeWithoutResponse;
      Future<void> _do(bool noResp) => chrRacp.write(v, withoutResponse: noResp);

      try {
        await _do(preferNoResp ? true : false); // ปกติใช้ with-response
      } on fbp.FlutterBluePlusException catch (e) {
        final msg = e.toString().toLowerCase(); // <-- ใช้ toString() แทน errorString
        final isLen13 = msg.contains('android-code: 13') || msg.contains('gatt_invalid_attribute_length');
        if (isLen13) {
          await Future.delayed(const Duration(milliseconds: 120));
          await _do(!preferNoResp); // สลับชนิด write แล้วลองใหม่
        } else {
          rethrow;
        }
      }
    }
    // =====================================================

    Future<void> _abort() async {
      try { await _safeWrite([0x03, 0x00]); await _awaitRacpOnce(); } catch (_) {}
    }
    Future<List<int>> _requestAndAck(List<int> cmd) async {
      await _safeWrite(cmd);
      final ack = await _awaitRacpOnce(); // รอ Response Code ปิดงาน
      if (ack.isNotEmpty) _controller.add({'racp': _hex(ack)});
      return ack;
    }
    bool _ok(List<int> a) => (a.length >= 4 && a[0] == 0x06 && a[2] == 0x01 && a[3] == 0x01);

    // 1) ขอจำนวนเรคอร์ดก่อน
    await _safeWrite([0x04, 0x01]);                 // Report number (All)
    final rnum = await _awaitRacpOnce();            // คาดหวัง [0x05,0x00,count_lo,count_hi]
    int count = (rnum.length >= 4 && rnum[0] == 0x05 && rnum[1] == 0x00)
        ? (rnum[2] | (rnum[3] << 8))
        : 0;
    if (count == 0) { _controller.add({'racp_num': '0'}); return _controller.stream; }
    _controller.add({'racp_num': count.toString()});

    // 2) ขอเรคอร์ด + fallback
    List<int> ack = <int>[];
    if (fetchLastOnly) {
      ack = await _requestAndAck([0x01, 0x06]);     // last
      if (!_ok(ack)) { await _abort(); ack = await _requestAndAck([0x01, 0x01]); } // all
    } else {
      ack = await _requestAndAck([0x01, 0x01]);     // all
    }
    if (!_ok(ack)) {                                 // >= seq 1
      await _abort();
      ack = await _requestAndAck([0x01, 0x03, 0x01, 0x01, 0x00]);
    }
    if (!_ok(ack)) {                                 // within 0..65535
      await _abort();
      ack = await _requestAndAck([0x01, 0x04, 0x01, 0x00, 0x00, 0xFF, 0xFF]);
    }

    // success แล้ว device จะ notify 0x2A18 เข้ามาเอง
    return _controller.stream;
  }

  Future<void> dispose() async {
    await _subMeas?.cancel();
    await _subRacp?.cancel();
    await _controller.close();
  }

  // ---------- Parser: Glucose Measurement (0x2A18) ----------
  Map<String, String>? _parseGlucoseMeasurement(List<int> data) {
    if (data.length < 10) return null;

    int i = 0;
    final flags = data[i++];
    final hasTimeOffset = (flags & 0x01) != 0;
    final hasConcTypeLoc = (flags & 0x02) != 0;
    final isMolPerL      = (flags & 0x04) != 0;
    final hasStatus      = (flags & 0x08) != 0;

    if (data.length < i + 2) return null;
    final seq = data[i] | (data[i + 1] << 8);
    i += 2;

    if (data.length < i + 7) return null;
    final year   = data[i] | (data[i + 1] << 8);
    final month  = data[i + 2];
    final day    = data[i + 3];
    final hour   = data[i + 4];
    final minute = data[i + 5];
    final second = data[i + 6];
    i += 7;
    final ts = _fmtTs(year, month, day, hour, minute, second);

    int? timeOffset;
    if (hasTimeOffset) {
      if (data.length < i + 2) return null;
      timeOffset = _toInt16le(data[i], data[i + 1]);
      i += 2;
    }

    double? mmolL, mgdL;
    if (hasConcTypeLoc) {
      if (data.length < i + 3) return null; // SFLOAT16 (2) + type/loc (1)
      final conc = _decodeSfloat16(data[i], data[i + 1]);
      i += 2;
      final _typeLoc = data[i]; // not used
      i += 1;

      if (conc != null) {
        if (isMolPerL) { mmolL = conc * 1000.0; mgdL = mmolL * 18.0; }
        else {            mgdL = conc * 100000.0; mmolL = mgdL * 0.0555; }
      }
    }

    if (hasStatus && data.length >= i + 2) {
      final _status = data[i] | (data[i + 1] << 8);
      i += 2;
    }

    if (mmolL == null && mgdL == null) return null;
    mmolL ??= mgdL! * 0.0555;
    mgdL  ??= mmolL * 18.0;

    return {
      'mgdl': mgdL.toStringAsFixed(0),
      'mmol': mmolL.toStringAsFixed(2),
      'seq' : seq.toString(),
      'ts'  : ts,
      if (timeOffset != null) 'time_offset': timeOffset.toString(),
      'raw' : _hex(data),
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
    if (raw == 0x07FF || raw == 0x0800 || raw == 0x07FE) return null;
    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x0008) != 0) exponent |= ~0x000F;
    return mantissa * math.pow(10.0, exponent).toDouble();
  }

  Future<void> _writeCurrentTime(BluetoothCharacteristic chrCT) async {
    final now = DateTime.now();
    final payload = <int>[
      now.year & 0xFF, (now.year >> 8) & 0xFF,
      now.month, now.day, now.hour, now.minute, now.second,
      (now.weekday % 7) + 1,
      0x00, // fractions256
      0x00, // adjust reason
    ];
    await chrCT.write(payload, withoutResponse: false);
  }

  String _fmtTs(int y, int m, int d, int h, int min, int s) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${y.toString().padLeft(4, '0')}-${two(m)}-${two(d)} ${two(h)}:${two(min)}:${two(s)}';
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}

// helper: .firstOrNull()
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
