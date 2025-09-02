// lib/core/device/add_device/Jumper/jumper_jpd_bfs710.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Cand { _Cand(this.notify, this.writer);
  final BluetoothCharacteristic notify;
  final BluetoothCharacteristic? writer;
}
class _Decoded { _Decoded(this.kg, this.stable);
  final double kg; final bool stable;
}

class JumperJpdBfs710 {
  JumperJpdBfs710({
    required this.device,
    this.enableLog = false,
    this.forceNotify,
    this.probeWindow = const Duration(seconds: 3),
    this.warmupFrameCount = 2,   // ข้ามเฟรมวอร์มอัปนิดหน่อย
  });

  final BluetoothDevice device;
  final bool enableLog;
  final Guid? forceNotify;
  final Duration probeWindow;
  final int warmupFrameCount;

  // FFB0/FEE0
  static final Guid _svcFFB0 = Guid('0000ffb0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFFB1 = Guid('0000ffb1-0000-1000-8000-00805f9b34fb'); // write
  static final Guid _chrFFB2 = Guid('0000ffb2-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid _svcFEE0 = Guid('0000fee0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFEE1 = Guid('0000fee1-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid _chrFEE2 = Guid('0000fee2-0000-1000-8000-00805f9b34fb'); // write
  static final Guid _chrFEE3 = Guid('0000fee3-0000-1000-8000-00805f9b34fb'); // notify

  static const _spKeyPrefix = 'bfs710_notify_char_';

  // streams
  final _liveCtrl   = StreamController<double>.broadcast(); // live 0 → จริง
  final _stableCtrl = StreamController<double>.broadcast(); // ใช้บันทึก
  Stream<double> get onWeightKg => _liveCtrl.stream;
  Stream<double> get onStableKg => _stableCtrl.stream;

  final _debugLogCtrl = StreamController<String>.broadcast();
  Stream<String> get onDebugLog => _debugLogCtrl.stream;

  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<List<int>>? _sub;

  int _framesSinceStart = 0;
  bool _preferAc = false;         // เห็นโปรโตคอล AC แล้ว
  double? _lastLive;

  // stable gate (จับค่าสุดท้าย)
  double? _peak;     // ค่าสูงสุดระหว่างยืน
  double? _last;     // ค่าเฟรมก่อนหน้า
  int _sameCount = 0;
  bool _locked = false;

  Future<void> start() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}

    var st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 8), autoConnect: false);
      st = await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 8));
      if (st != BluetoothConnectionState.connected) {
        throw StateError('BFS710: เชื่อมต่อไม่สำเร็จ');
      }
    }

    // discover
    List<BluetoothService> svcs = [];
    for (int i = 0; i < 3; i++) {
      svcs = await device.discoverServices();
      if (svcs.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    final cands = _collectCandidates(svcs);
    if (cands.isEmpty) throw StateError('BFS710: ไม่พบ characteristic แบบ Notify');

    // 1) ใช้ตัวที่เคยจำ
    final saved = await _loadPreferred();
    if (saved != null) {
      final picked = cands.firstWhere((c) => c.notify.uuid == saved, orElse: () => cands.first);
      await _useCandidate(picked, remember: false);
      _log('SELECT (saved): ${_labelOf(picked.notify)}');
      return;
    }

    // 2) force
    if (forceNotify != null) {
      final pick = cands.firstWhere((c) => c.notify.uuid == forceNotify,
        orElse: () => throw StateError('BFS710: ไม่พบ forceNotify: ${forceNotify!.str}'));
      await _useCandidate(pick, remember: true);
      _log('SELECT (forced): ${_labelOf(pick.notify)}');
      return;
    }

    // 3) probe แล้วจำ
    final chosen = await _probe(cands);
    await _useCandidate(chosen, remember: true);
    _log('SELECT: ${_labelOf(chosen.notify)}');
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try { if (_notifyChar != null) await _notifyChar!.setNotifyValue(false); } catch (_) {}
  }

  // ── persist chosen characteristic ──
  Future<Guid?> _loadPreferred() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('$_spKeyPrefix${device.remoteId.str}');
    return (s == null || s.isEmpty) ? null : Guid(s);
  }
  Future<void> _savePreferred(Guid g) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_spKeyPrefix${device.remoteId.str}', g.str);
  }

  // ── candidates & probe ──
  List<_Cand> _collectCandidates(List<BluetoothService> svcs) {
    BluetoothCharacteristic? find(Guid svc, Guid chr) {
      for (final s in svcs) {
        if (s.uuid == svc) {
          for (final c in s.characteristics) { if (c.uuid == chr) return c; }
        }
      }
      return null;
    }
    final ffb2 = find(_svcFFB0, _chrFFB2);
    final ffb1 = find(_svcFFB0, _chrFFB1);
    final fee1 = find(_svcFEE0, _chrFEE1);
    final fee2 = find(_svcFEE0, _chrFEE2);
    final fee3 = find(_svcFEE0, _chrFEE3);

    final out = <_Cand>[];
    if (ffb2 != null && (ffb2.properties.notify || ffb2.properties.indicate)) {
      out.add(_Cand(ffb2, (ffb1 != null && (ffb1.properties.write || ffb1.properties.writeWithoutResponse)) ? ffb1 : null));
    }
    if (fee1 != null && (fee1.properties.notify || fee1.properties.indicate)) {
      out.add(_Cand(fee1, (fee2 != null && (fee2.properties.write || fee2.properties.writeWithoutResponse)) ? fee2 : null));
    }
    if (fee3 != null && (fee3.properties.notify || fee3.properties.indicate)) {
      out.add(_Cand(fee3, (fee2 != null && (fee2.properties.write || fee2.properties.writeWithoutResponse)) ? fee2 : null));
    }
    return out;
  }

  Future<_Cand> _probe(List<_Cand> cands) async {
    _log('PROBE start (${cands.length})');
    _Cand? best; int bestHits = -1; double? bestW;

    for (final cand in cands) {
      final label = _labelOf(cand.notify);
      StreamSubscription<List<int>>? sub; int hits = 0; double? w;

      try {
        await cand.notify.setNotifyValue(false);
        await cand.notify.setNotifyValue(true);
        if (cand.writer != null) {
          try { await cand.writer!.write([0x01], withoutResponse: true); }
          catch (_) { try { await cand.writer!.write([0x01], withoutResponse: false); } catch (_) {} }
        }
        sub = cand.notify.value.listen((d) {
          hits++; _debugFrame(label, d);
          final dec = _decode(d);
          if (dec != null) w ??= dec.kg;
        });
        await Future.any([
          Future.delayed(probeWindow),
          (() async {
            final t0 = DateTime.now();
            while (DateTime.now().difference(t0) < probeWindow) {
              await Future.delayed(const Duration(milliseconds: 60));
              if (hits > 0) break;
            }
            if (hits > 0) await Future.delayed(const Duration(milliseconds: 200));
          })(),
        ]);
      } finally {
        await sub?.cancel();
        try { await cand.notify.setNotifyValue(false); } catch (_) {}
      }

      _log('HITS($label)=$hits, weight=${w?.toStringAsFixed(1) ?? '-'}');
      if (w != null) { best = cand; bestHits = hits; bestW = w; break; }
      if (hits > bestHits) { best = cand; bestHits = hits; }
    }

    best ??= cands.first;
    _log('PROBE result: ${_labelOf(best.notify)} (hits=$bestHits, weight=${bestW?.toStringAsFixed(1) ?? '-'})');
    return best;
  }

  Future<void> _useCandidate(_Cand cand, {required bool remember}) async {
    _notifyChar = cand.notify;
    _writeChar  = cand.writer;
    _framesSinceStart = 0; _preferAc = false;
    _resetStableGate();

    await _notifyChar!.setNotifyValue(true);
    if (_writeChar != null) {
      try { await _writeChar!.write([0x01], withoutResponse: true); }
      catch (_) { try { await _writeChar!.write([0x01], withoutResponse: false); } catch (_) {} }
    }
    if (remember) await _savePreferred(_notifyChar!.uuid);

    await _sub?.cancel();
    _sub = _notifyChar!.value.listen((d) {
      _framesSinceStart++;
      _debugFrame(_labelOf(_notifyChar!), d);

      final dec = _decode(d);
      if (dec == null) return;

      // live: แสดงตั้งแต่ 0 ขึ้นไป (ข้ามวอร์มอัปแค่เล็กน้อย)
      if (_framesSinceStart > warmupFrameCount) {
        _lastLive = dec.kg;
        _liveCtrl.add(dec.kg);
        _feedStableGate(dec.kg); // ใช้กติกาปล่อยค่านิ่ง
      }
    }, onError: (_) {});
  }

  // ───────── decoders ─────────

  // โปรโตคอลหลัก (ที่เห็นในรูป): AC SS HH LL 00 00 CE XX
  _Decoded? _decodeAcFrame(List<int> d) {
    for (int i = 0; i + 3 < d.length; i++) {
      if (d[i] == 0xAC) {
        final status = d[i + 1] & 0xff;     // บางล็อตอาจไม่มีบิตนิ่ง
        final hh = d[i + 2] & 0xff;
        final ll = d[i + 3] & 0xff;
        final raw = (hh << 8) | ll;         // BE
        final kg  = raw / 100.0;
        final stable = (status & 0x20) != 0 || (status & 0x10) != 0;
        if (_inRange(kg)) return _Decoded(_round1(kg), stable);
      }
    }
    return null;
  }

  _Decoded? _decode(List<int> d) {
    // ถ้าเคยเห็น AC แล้ว → ใช้เฉพาะ AC (กันค่าเพี้ยนจากเฟรมอื่น)
    final ac = _decodeAcFrame(d);
    if (ac != null) { _preferAc = true; return ac; }
    if (_preferAc) return null;

    // fallback (คงไว้กรณีบางล็อตไม่ใช่ AC)
    for (int i = 0; i + 3 < d.length; i++) {
      final status = d[i + 1] & 0xff;
      final hi = d[i + 2] & 0xff;
      final lo = d[i + 3] & 0xff;
      final rawLE = (lo) | (hi << 8);
      final rawBE = (hi << 8) | lo;
      for (final raw in [rawLE, rawBE]) {
        for (final div in [10.0, 100.0]) {
          final kg = raw / div;
          final stable = (status & 0x20) != 0 || (status & 0x10) != 0 || (status & 0x04) != 0;
          if (_inRange(kg)) return _Decoded(_round1(kg), stable);
        }
      }
    }
    return null;
  }

  bool _inRange(double v) => v >= 0.0 && v <= 250.0; // live ต้องเริ่มที่ 0 ได้
  double _round1(double x) => (x * 10).round() / 10.0;

  // ───────── stable gate ─────────
  void _resetStableGate() { _peak = null; _last = null; _sameCount = 0; _locked = false; }

  void _feedStableGate(double kg) {
    if (_locked) {
      // ปลดล็อกเมื่อยกเท้า (< 10 kg)
      if (kg < 10.0) _locked = false;
      return;
    }

    // เก็บ peak และความต่อเนื่อง
    _peak = (_peak == null) ? kg : (kg > _peak! ? kg : _peak);
    if (_last != null && (_round1(kg) == _round1(_last!))) _sameCount++; else _sameCount = 1;
    _last = kg;

    // เงื่อนไข "นิ่งแล้ว": ซ้ำ ≥3 เฟรม หรือมี downtrend ชัดเจน (เริ่มลดจากยอด ≥0.4 kg)
    final downtrend = (_peak != null) && ((_peak! - kg) >= 0.4);
    if (_sameCount >= 3 || downtrend) {
      final out = _round1(_peak ?? kg);
      _stableCtrl.add(out);
      _locked = true;
    }
  }

  // ───────── logging ─────────
  void _debugFrame(String label, List<int> d) {
    if (!enableLog && !_debugLogCtrl.hasListener) return;
    final hex = d.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final msg = '[$label] $hex';
    if (enableLog) { print('[BFS710] $msg'); } // ignore: avoid_print
    if (_debugLogCtrl.hasListener) _debugLogCtrl.add(msg);
  }
  void _log(String msg) {
    if (enableLog) { print('[BFS710] $msg'); } // ignore: avoid_print
    if (_debugLogCtrl.hasListener) _debugLogCtrl.add(msg);
  }
  String _labelOf(BluetoothCharacteristic c) {
    final u = c.uuid;
    if (u == _chrFFB2) return 'FFB2';
    if (u == _chrFEE1) return 'FEE1';
    if (u == _chrFEE3) return 'FEE3';
    return u.str;
  }
}
