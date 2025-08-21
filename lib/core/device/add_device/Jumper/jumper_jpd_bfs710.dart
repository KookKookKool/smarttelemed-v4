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

/// Jumper JPD-BFS710
class JumperJpdBfs710 {
  JumperJpdBfs710({
    required this.device,
    this.enableLog = false,
    this.forceNotify,
    this.probeWindow = const Duration(seconds: 3),
    this.minReportKg = 20.0,     // กัน noise ตอนยังไม่นิ่ง
    this.warmupFrameCount = 3,   // ข้ามเฟรมวอร์มอัป
  });

  final BluetoothDevice device;
  final bool enableLog;
  final Guid? forceNotify;
  final Duration probeWindow;
  final double minReportKg;
  final int warmupFrameCount;

  // FFB0/FEE0 family
  static final Guid _svcFFB0 = Guid('0000ffb0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFFB1 = Guid('0000ffb1-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFFB2 = Guid('0000ffb2-0000-1000-8000-00805f9b34fb');
  static final Guid _svcFEE0 = Guid('0000fee0-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFEE1 = Guid('0000fee1-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFEE2 = Guid('0000fee2-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFEE3 = Guid('0000fee3-0000-1000-8000-00805f9b34fb');

  static const _spKeyPrefix = 'bfs710_notify_char_';

  // streams
  final _controller = StreamController<double>.broadcast();      // ทุกเฟรม
  final _stableCtrl = StreamController<double>.broadcast();      // เฉพาะเฟรมที่นิ่ง (สำหรับ "บันทึก")
  Stream<double> get onWeightKg => _controller.stream;
  Stream<double> get onStableKg => _stableCtrl.stream;

  final _debugLogCtrl = StreamController<String>.broadcast();
  Stream<String> get onDebugLog => _debugLogCtrl.stream;

  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<List<int>>? _sub;

  int _framesSinceStart = 0;
  double? _lastEmittedKg;

  // stable gate
  double? _lastQuant;  // ค่าปัด 1 ตำแหน่งล่าสุด
  int _repeat = 0;     // ซ้ำกี่เฟรมแล้ว
  bool _locked = false; // ล็อกหลังปล่อยค่าหนึ่งครั้งจนกว่าจะยกเท้าออก

  // ───────── lifecycle ─────────
  Future<void> start() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}

    var st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 8), autoConnect: false);
      st = await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 8));
      if (st != BluetoothConnectionState.connected) throw StateError('BFS710: เชื่อมต่อไม่สำเร็จ');
    }

    // discover
    List<BluetoothService> svcs = [];
    for (int i = 0; i < 3; i++) {
      svcs = await device.discoverServices();
      if (svcs.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    final candidates = _collectCandidates(svcs);
    if (candidates.isEmpty) throw StateError('BFS710: ไม่พบ characteristic แบบ Notify (FFB2/FEE1/FEE3)');

    // 1) ใช้ char ที่เคยจำไว้ต่อ device นี้
    final saved = await _loadPreferredNotifyGuid();
    if (saved != null) {
      final picked = candidates.firstWhere((c) => c.notify.uuid == saved, orElse: () => candidates.first);
      await _useCandidate(picked, remember: false);
      _log('SELECT (saved): ${_labelOf(picked.notify)}');
      return;
    }

    // 2) force
    if (forceNotify != null) {
      final pick = candidates.firstWhere((c) => c.notify.uuid == forceNotify,
          orElse: () => throw StateError('BFS710: ไม่พบ forceNotify: ${forceNotify!.str}'));
      await _useCandidate(pick, remember: true);
      _log('SELECT (forced): ${_labelOf(pick.notify)}');
      return;
    }

    // 3) probe แล้วจำ
    final chosen = await _probeCandidatesSequential(candidates);
    await _useCandidate(chosen, remember: true);
    _log('SELECT: ${_labelOf(chosen.notify)}');
  }

  Future<void> stop() async {
    await _sub?.cancel(); _sub = null;
    try { if (_notifyChar != null) await _notifyChar!.setNotifyValue(false); } catch (_) {}
  }

  // ───────── persist preferred char ─────────
  Future<Guid?> _loadPreferredNotifyGuid() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('$_spKeyPrefix${device.remoteId.str}');
    return (s == null || s.isEmpty) ? null : Guid(s);
  }
  Future<void> _savePreferredNotifyGuid(Guid g) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_spKeyPrefix${device.remoteId.str}', g.str);
  }

  // ───────── candidates/probe ─────────
  List<_Cand> _collectCandidates(List<BluetoothService> svcs) {
    BluetoothCharacteristic? findChar(Guid svcId, Guid charId) {
      for (final s in svcs) {
        if (s.uuid == svcId) {
          for (final c in s.characteristics) {
            if (c.uuid == charId) return c;
          }
        }
      }
      return null;
    }
    final ffb2 = findChar(_svcFFB0, _chrFFB2);
    final ffb1 = findChar(_svcFFB0, _chrFFB1);
    final fee1 = findChar(_svcFEE0, _chrFEE1);
    final fee2 = findChar(_svcFEE0, _chrFEE2);
    final fee3 = findChar(_svcFEE0, _chrFEE3);

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

  Future<_Cand> _probeCandidatesSequential(List<_Cand> cands) async {
    _log('PROBE start (${cands.length} candidates)');
    _Cand? best; int bestHits = -1; double? bestWeight;

    for (final cand in cands) {
      final label = _labelOf(cand.notify);
      _log('TRY: $label');
      StreamSubscription<List<int>>? tempSub; int hits = 0; double? found;

      try {
        await cand.notify.setNotifyValue(false);
        await cand.notify.setNotifyValue(true);
        if (cand.writer != null) {
          try { await cand.writer!.write([0x01], withoutResponse: true); }
          catch (_) { try { await cand.writer!.write([0x01], withoutResponse: false); } catch (_) {} }
        }

        tempSub = cand.notify.value.listen((data) {
          hits++; _debugFrame(label, data);
          final dec = _decode(data);
          if (dec != null) found ??= dec.kg;
        });

        await Future.any([
          Future.delayed(probeWindow),
          (() async { final t0 = DateTime.now();
            while (DateTime.now().difference(t0) < probeWindow) {
              await Future.delayed(const Duration(milliseconds: 60));
              if (hits > 0) break;
            }
            if (hits > 0) await Future.delayed(const Duration(milliseconds: 200));
          })(),
        ]);
      } finally {
        await tempSub?.cancel();
        try { await cand.notify.setNotifyValue(false); } catch (_) {}
      }

      _log('HITS($label)=$hits, weight=${found?.toStringAsFixed(1) ?? '-'}');
      if (found != null) { best = cand; bestHits = hits; bestWeight = found; break; }
      if (hits > bestHits) { best = cand; bestHits = hits; }
    }

    best ??= cands.first;
    _log('PROBE result: ${_labelOf(best.notify)} (hits=$bestHits, weight=${bestWeight?.toStringAsFixed(1) ?? '-'})');
    return best;
  }

  Future<void> _useCandidate(_Cand cand, {required bool remember}) async {
    _notifyChar = cand.notify;
    _writeChar  = cand.writer;
    _framesSinceStart = 0;
    _resetStableGate();

    await _notifyChar!.setNotifyValue(true);
    if (_writeChar != null) {
      try { await _writeChar!.write([0x01], withoutResponse: true); }
      catch (_) { try { await _writeChar!.write([0x01], withoutResponse: false); } catch (_) {} }
    }
    if (remember) await _savePreferredNotifyGuid(_notifyChar!.uuid);

    await _sub?.cancel();
    _sub = _notifyChar!.value.listen((data) {
      _framesSinceStart++;
      _debugFrame(_labelOf(_notifyChar!), data);

      final dec = _decode(data);
      if (dec == null) return;

      // วอร์มอัป
      if (_framesSinceStart <= warmupFrameCount) return;

      // กัน noise ตอนยังไม่นิ่ง
      if (!dec.stable && dec.kg < minReportKg) return;

      // stream "ทุกเฟรม" (โชว์บนจอได้)
      _lastEmittedKg = dec.kg;
      _controller.add(dec.kg);

      // stream "เฉพาะค่านิ่ง" (ใช้บันทึกจริง)
      _feedStableGate(dec.kg);
    }, onError: (_) {});
  }

  // ───────── decoders ─────────

  // รูปแบบหลักของ BFS: AC SS HH LL 00 00 CE xx  → kg = (HHLL)/100
  _Decoded? _decodeBfsAcFrame(List<int> d) {
    for (int i = 0; i + 3 < d.length; i++) {
      if (d[i] == 0xAC) {
        final status = d[i + 1] & 0xff;
        final hh = d[i + 2] & 0xff;
        final ll = d[i + 3] & 0xff;
        final raw = (hh << 8) | ll;       // BE
        final kg = raw / 100.0;
        final stable = (status & 0x20) != 0 || (status & 0x10) != 0; // บิตนิ่ง (บางล็อต)
        if (_inRange(kg)) return _Decoded(_round1(kg), stable);
      }
    }
    return null;
  }

  _Decoded? _decode(List<int> d) {
    final ac = _decodeBfsAcFrame(d);
    if (ac != null) return ac;

    // generic flags fallback (ไม่แปลงเป็น jin/lb ที่บิตอีกต่อไป)
    for (int i = 0; i + 3 < d.length; i++) {
      final status = d[i + 1] & 0xff;
      final hi = d[i + 2] & 0xff;
      final lo = d[i + 3] & 0xff;
      final rawLE = (lo) | (hi << 8);
      final rawBE = (hi << 8) | lo;
      for (final raw in [rawLE, rawBE]) {
        for (final div in [10.0, 100.0]) {
          final kg = (raw / div);
          final stable = (status & 0x20) != 0 || (status & 0x10) != 0 || (status & 0x04) != 0;
          if (_inRange(kg)) return _Decoded(_round1(kg), stable);
        }
      }
    }

    // ASCII/heuristic (สุดท้าย)
    final akg = _decodeAsciiAllCandidates(d);
    if (akg != null) return _Decoded(_round1(akg), false);

    final hk = _extractWeightHeuristic(d);
    if (hk != null) return _Decoded(_round1(hk), false);

    return null;
  }

  double? _decodeAsciiAllCandidates(List<int> d) {
    final s = String.fromCharCodes(d);
    final low = s.toLowerCase();
    String unitNear(int idx) {
      final start = ((idx - 8).clamp(0, low.length)).toInt();
      final end   = ((idx + 12).clamp(0, low.length)).toInt();
      final win = low.substring(start, end);
      if (win.contains('kg')) return 'kg';
      if (win.contains('lb')) return 'lb';
      if (win.contains('jin') || win.contains('斤')) return 'jin';
      return '';
    }
    final ms = RegExp(r'(\d{2,3}(?:\.\d+)?)').allMatches(s).toList();
    if (ms.isEmpty) return null;
    final c = <double>[];
    for (final m in ms) {
      final num = double.tryParse(m.group(1)!);
      if (num == null) continue;
      final u = unitNear(m.start);
      double kg = num;
      if (u == 'lb') kg = num / 2.20462; else if (u == 'jin') kg = num * 0.5;
      else if (!_inRange(kg) && _inRange(num / 2)) kg = num / 2;
      if (_inRange(kg)) c.add(kg);
    }
    if (c.isEmpty) return null;
    return _chooseBest(c);
  }

  double? _extractWeightHeuristic(List<int> d) {
    if (d.isEmpty) return null;
    final c = <double>[];
    for (int i = 0; i + 1 < d.length; i++) {
      final le = (d[i] & 0xff) | ((d[i + 1] & 0xff) << 8);
      final be = ((d[i] & 0xff) << 8) | (d[i + 1] & 0xff);
      for (final v in [le / 10.0, be / 10.0, le / 100.0, be / 100.0]) {
        if (_inRange(v)) c.add(v);
      }
    }
    if (c.isEmpty) return null;
    return _chooseBest(c);
  }

  double _chooseBest(List<double> candidates) {
    double? best; int bestScore = 1 << 30;
    for (final v in candidates) {
      int s = 0;
      if (v < minReportKg) s += 100;
      if (_lastEmittedKg != null) {
        final diff = (v - _lastEmittedKg!).abs();
        s += (diff * 10).round();
      } else if (v < minReportKg) { s += 10; }
      if ((v * 2).roundToDouble() == (v * 2)) s -= 2;   // .0/.5
      if ((v * 10).roundToDouble() == (v * 10)) s -= 1; // 1 ตำแหน่งพอดี
      if (best == null || s < bestScore || (s == bestScore && v > best)) { best = v; bestScore = s; }
    }
    return best!;
  }

  bool _inRange(double v) => v >= 5.0 && v <= 250.0;
  double _round1(double x) => (x * 10).round() / 10.0;

  // ───────── stable gate ─────────
  void _resetStableGate() {
    _lastQuant = null; _repeat = 0; _locked = false;
  }

  void _feedStableGate(double kg) {
    final q = _round1(kg);

    // ปลดล็อกเมื่อยกเท้า (<10 kg)
    if (_locked) {
      if (kg < 10.0) { _locked = false; _repeat = 0; _lastQuant = null; }
      return;
    }

    if (_lastQuant != null && (q == _lastQuant)) {
      _repeat++;
    } else {
      _lastQuant = q;
      _repeat = 1;
    }

    // ต้องซ้ำ ≥ 3 เฟรม ถึงจะถือว่า "นิ่ง" แล้วปล่อยไปบันทึก
    if (_repeat >= 3) {
      _stableCtrl.add(q);
      _locked = true; // กันปล่อยซ้ำ ๆ ระหว่างยืนค้าง
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
