// lib/core/device/add_device/Yuwell/yuwellglucose_simple.dart
import 'dart:async';
import 'dart:math' show pow;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

class YuwellGlucose {
  final BluetoothDevice device;
  YuwellGlucose({required this.device});

  static final Guid _svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid _chrMeas    = Guid('00002A18-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid _chrRacp    = Guid('00002A52-0000-1000-8000-00805f9b34fb'); // indicate + write

  // สตรีมเดิม: ส่ง mg/dL (string)
  final _ctrl = StreamController<String>.broadcast();
  // สตรีมรายละเอียด (ใช้เมื่อเรียก records())
  StreamController<Map<String, String>>? _recCtrl;

  StreamSubscription<List<int>>? _subMeas, _subRacp;
  BluetoothCharacteristic? _cMeas, _cRacp;

  Future<void> _ensureConnected() async {
    try { await device.requestMtu(247); } catch (_) {}
    final st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(autoConnect: false);
      await device.connectionState.where((s) => s == BluetoothConnectionState.connected).first;
    }
  }

  // ---------- One-shot: เอา "เรคอร์ดล่าสุด" จริง ๆ ----------
  Future<Map<String,String>> getLatestRecord({Duration timeout = const Duration(seconds: 6)}) async {
    await _ensureConnected();

    // discover & pick chr
    if (_cMeas == null || _cRacp == null) {
      final svcs = await device.discoverServices();
      final svc = svcs.firstWhere((s) => s.uuid == _svcGlucose, orElse: () => throw 'ไม่พบ 0x1808');
      for (final c in svc.characteristics) {
        if (c.uuid == _chrMeas) _cMeas = c;
        if (c.uuid == _chrRacp) _cRacp = c;
      }
      if (_cMeas == null || _cRacp == null) throw 'ไม่พบ 0x2A18/0x2A52';
    }

    // เปิด notify/indicate
    try { await _cMeas!.setNotifyValue(true); } catch (_) {}
    try { await _cRacp!.setNotifyValue(true); } catch (_) {}

    // รอ measurement แรกจาก 2A18 แล้วจบ
    final fut = _cMeas!.value
        .map((raw) => _decodeRec(Uint8List.fromList(raw)))
        .where((rec) => rec != null)
        .cast<GlucoseRecord>()
        .map((rec) => rec.toMap())
        .first
        .timeout(timeout);

    // ขอ "เรคอร์ดสุดท้าย" ตามสเปค: Report Stored Records (0x01) + Operator Last (0x06)
    await _writeRacp([0x01, 0x06]);

    return await fut;
  }

  /// สตรีมตัวเลขเดิม (เพื่อความเข้ากันได้) — ถ้า fetchLastOnly=true จะ "ขอ last" ตรง ๆ
  Stream<String> parse({bool fetchLastOnly = true}) {
    () async {
      try {
        await _ensureConnected();

        final svcs = await device.discoverServices();
        final svc = svcs.firstWhere(
          (s) => s.uuid == _svcGlucose,
          orElse: () => throw 'ไม่พบ Glucose Service (0x1808)',
        );
        for (final c in svc.characteristics) {
          if (c.uuid == _chrMeas) _cMeas = c;
          if (c.uuid == _chrRacp) _cRacp = c;
        }
        if (_cMeas == null || _cRacp == null) {
          throw 'ไม่พบ 0x2A18 หรือ 0x2A52';
        }

        await _cMeas!.setNotifyValue(true);
        _subMeas = _cMeas!.value.listen((raw) {
          final rec = _decodeRec(Uint8List.fromList(raw));
          if (rec != null) {
            _ctrl.add(rec.mgdl.toStringAsFixed(0));
            _recCtrl?.add(rec.toMap());
            debugPrint('GLU rec: seq=${rec.seq} time=${rec.time.toIso8601String()} '
                'mg/dL=${rec.mgdl.toStringAsFixed(0)} mmol=${rec.mmol.toStringAsFixed(1)}');
          } else {
            debugPrint('2A18 decode=null raw=${_hex(raw)}');
          }
        }, onError: (e) => debugPrint('glucose meas err: $e'));

        await _cRacp!.setNotifyValue(true);
        _subRacp = _cRacp!.value.listen((raw) {
          debugPrint('RACP ind: ${_hex(raw)}');
          // ไม่ต้องแปลง count → seq แล้วอีกต่อไป
          // แค่รับ general responses ไว้ดูสถานะ
        }, onError: (e) => debugPrint('glucose racp err: $e'));

        // ----- Kick off -----
        await Future.delayed(const Duration(milliseconds: 200));
        if (fetchLastOnly) {
          // ✅ ขอ "ล่าสุด" ตรง ๆ
          await _writeRacp([0x01, 0x06]);
          // กันเงียบ: ถ้า 2 วิไม่มา ลองขอ "ทั้งหมด" (แล้ว UI กรองเอาค่าแรกที่มาหรือใช้ take(1) ข้างนอก)
          Future.delayed(const Duration(seconds: 2), () async {
            if (!_ctrl.hasListener) return;
            try { await _writeRacp([0x01, 0x01]); } catch (_) {}
          });
        } else {
          // ดึงทั้งหมด
          await _writeRacp([0x01, 0x01]);
        }
      } catch (e, st) {
        debugPrint('YuwellGlucose error: $e\n$st');
        _ctrl.addError(e);
      }
    }();

    _ctrl.onCancel = () async {
      try { await _subMeas?.cancel(); } catch (_) {}
      try { await _subRacp?.cancel(); } catch (_) {}
      try { if (_cMeas != null) await _cMeas!.setNotifyValue(false); } catch (_) {}
      try { if (_cRacp != null) await _cRacp!.setNotifyValue(false); } catch (_) {}
      if (_recCtrl != null && !_recCtrl!.hasListener) {
        try { await _recCtrl!.close(); } catch (_) {}
        _recCtrl = null;
      }
    };

    return _ctrl.stream;
  }

  /// รายละเอียดครบ (ใช้กับ UI ที่อยากโชว์เวลา/ลำดับ) — ถ้า fetchLastOnly=true แนะนำใช้ .take(1) ที่ฝั่ง UI
  Stream<Map<String, String>> records({bool fetchLastOnly = true}) {
    if (_recCtrl != null) {
      try { _recCtrl!.close(); } catch (_) {}
      _recCtrl = null;
    }
    final rec = _recCtrl = StreamController<Map<String, String>>.broadcast();

    final boot = parse(fetchLastOnly: fetchLastOnly).listen(
      (_) {}, // ทิ้งตัวเลข
      onError: (e) => rec.addError(e),
    );

    rec.onCancel = () async {
      await boot.cancel();
      if (_recCtrl == rec) {
        try { await _recCtrl!.close(); } catch (_) {}
        _recCtrl = null;
      }
    };
    return rec.stream;
  }

  // ---------- Helpers ----------
  Future<void> _writeRacp(List<int> bytes) async {
    if (_cRacp == null) throw 'RACP not ready';
    debugPrint('RACP write: ${_hex(bytes)}');
    await _cRacp!.write(bytes, withoutResponse: false);
  }

  GlucoseRecord? _decodeRec(Uint8List data) {
    if (data.isEmpty) return null;
    int i = 0;
    int _u16(int idx) => data[idx] | (data[idx + 1] << 8);

    final flags = data[i++];
    final seq   = _u16(i); i += 2;

    final year   = _u16(i); i += 2;
    final month  = data[i++];
    final day    = data[i++];
    final hour   = data[i++];
    final minute = data[i++];
    final second = data[i++];
    DateTime t = DateTime(year, month, day, hour, minute, second);

    if ((flags & 0x01) != 0) {
      final off = _u16(i).toSigned(16); i += 2;
      t = t.add(Duration(minutes: off));
    }

    if ((flags & 0x02) == 0 || data.length < i + 3) return null;

    final sfloatRaw = _u16(i); i += 2;
    final typeLoc   = data[i++];

    final conc = _parseSfloat(sfloatRaw);
    if (conc == null) return null;

    final unitsMolPerL = (flags & 0x04) != 0;
    final mgdl = unitsMolPerL ? conc * 18015.0 : conc * 100000.0;
    final mmol = mgdl / 18.015;

    final type = typeLoc & 0x0F;
    final loc  = (typeLoc >> 4) & 0x0F;

    return GlucoseRecord(
      seq: seq,
      time: t,
      mgdl: mgdl,
      mmol: mmol,
      flags: flags,
      type: type,
      location: loc,
    );
  }

  double? _parseSfloat(int raw) {
    if (raw == 0x07FF || raw == 0x07FE || raw == 0x0800) return null;
    int mantissa = raw & 0x0FFF;
    int exponent = (raw >> 12) & 0xF;
    if (mantissa >= 0x800) mantissa -= 0x1000;
    if (exponent >= 0x8)  exponent -= 0x10;
    return mantissa * pow(10, exponent).toDouble();
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}

// -------- Data class --------
class GlucoseRecord {
  GlucoseRecord({
    required this.seq,
    required this.time,
    required this.mgdl,
    required this.mmol,
    required this.flags,
    this.type,
    this.location,
  });
  final int seq;
  final DateTime time;
  final double mgdl;
  final double mmol;
  final int flags;
  final int? type;
  final int? location;

  Map<String, String> toMap() => {
    'seq': seq.toString(),
    'time': time.toIso8601String(),
    'mgdl': mgdl.toStringAsFixed(0),
    'mmol': mmol.toStringAsFixed(1),
    'type': type?.toString() ?? '',
    'loc': location?.toString() ?? '',
  };
}
