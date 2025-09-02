// lib/core/device/dashboard/device_hub.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart'; // ChangeNotifier / Listenable
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice, ScanResult, BluetoothConnectionState;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

import 'package:smarttelemed_v4/shared/services/device/session/device_session.dart';
import 'package:smarttelemed_v4/shared/services/device/session/pick_parser.dart';
import 'package:smarttelemed_v4/shared/services/device/dashboard/vitals.dart';

class DeviceHub extends ChangeNotifier {
  DeviceHub._internal() { scheduleMicrotask(() => ensure()); }
  static final DeviceHub I = DeviceHub._internal();

  // ===== sessions =====
  final Map<String, DeviceSession> _sessions = {};
  List<DeviceSession> get sessions => _sessions.values.toList(growable: false);
  DeviceSession? sessionById(String id) => _sessions[id];

  // ===== poll connected list =====
  Timer? _poll;
  bool _started = false;
  bool _refreshing = false;

  // ===== auto-scan / auto-connect =====
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _scanFlagSub;
  bool _isScanning = false;
  Timer? _scanTimer;
  final Queue<String> _autoQ = Queue<String>();
  bool _autoBusy = false;
  final Map<String, DateTime> _lastTry = {};
  static const Duration _cooldown = Duration(seconds: 20);

  // allow-list (optional)
  Set<String> _installedIds = {}; // ว่าง = อนุญาตทุกเครื่องที่ผ่าน heuristic

  // heuristic: ชื่อ + GUID tails ที่มักใช้กับเครื่องแพทย์
  static const Set<String> _svcTails = {
    '1822', '1810', '1809', '1808', '181b', 'fff0', 'ffe0', 'ffb0', 'fee0',
  };
  static const List<String> _nameKeys = [
    'ye680', 'ua-651', 'ua651', 'ha120', 'bm57',
    'oximeter','spo','yx110','jumper','jpd','fr400','thermo','ft95','yuwell',
    'glucose','mibfs','scale','bfs','swan',
  ];

  // ---------- life-cycle ----------
  Future<void> ensureStarted() => ensure();

  Future<void> ensure() async {
    if (_started) return;
    _started = true;

    // โหลด allow-list ที่ผู้ใช้บันทึกไว้ (optional)
    try {
      final p = await SharedPreferences.getInstance();
      _installedIds = (p.getStringList('installed_device_ids') ?? const <String>[])
          .where((e) => e.trim().isNotEmpty)
          .toSet();
    } catch (_) {}

    await _refreshConnected(); // ครั้งแรก
    _startBackgroundScan();    // สแกนพื้นหลังต่อเนื่อง

    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_refreshing) return;
      _refreshing = true;
      try {
        await _refreshConnected();
      } finally {
        _refreshing = false;
      }
    });
  }

  Future<void> _refreshConnected() async {
    try {
      final devs = await fbp.FlutterBluePlus.connectedDevices;

      // add sessions for new devices
      for (final d in devs) {
        final id = d.remoteId.str;
        if (!_sessions.containsKey(id)) {
          await _createAndStartSession(d);
        }
      }

      // prune disconnected sessions
      final alive = devs.map((e) => e.remoteId.str).toSet();
      final stale = _sessions.keys.where((k) => !alive.contains(k)).toList();
      for (final id in stale) {
        await _sessions[id]?.dispose();
        _sessions.remove(id);
      }
    } catch (_) {
      // เงียบไว้
    } finally {
      notifyListeners();
    }
  }

  Future<void> _createAndStartSession(BluetoothDevice d) async {
    final id = d.remoteId.str;

    final sess = DeviceSession(
      device: d,
      onUpdate: () {
        final s = _sessions[id];
        if (s != null) _applySessionToVitals(s);
        notifyListeners();
      },
      onError: (_) => notifyListeners(),
      onDisconnected: () async {
        // เมื่อหลุด ให้รีเฟรชและปล่อยให้ auto-scan หาใหม่
        await _refreshConnected();
      },
    );

    _sessions[id] = sess;
    await sess.start(pickParser: pickParser);
  }

  // ---------- background scan / auto connect ----------
  void _startBackgroundScan() {
    // ยิงเป็นระยะ ๆ เพื่อไม่กินแบต/ไม่ค้างสแกน
    _scanTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_isScanning) _startScanOnce();
    });
  }

  void _startScanOnce() async {
    await _scanSub?.cancel();
    await _scanFlagSub?.cancel();

    _scanSub = fbp.FlutterBluePlus.scanResults.listen((results) async {
      final now = DateTime.now();
      for (final r in results) {
        final id = r.device.remoteId.str;

        if (_installedIds.isNotEmpty && !_installedIds.contains(id)) continue;
        if (!_looksSupported(r)) continue;

        final last = _lastTry[id];
        if (last != null && now.difference(last) < _cooldown) continue;

        final st = await r.device.connectionState.first;
        final connected = st == BluetoothConnectionState.connected;
        final known = _sessions.containsKey(id);

        if (!connected && !known) {
          _lastTry[id] = now;
          _enqueue(r.device);
        }
      }
    });

    _scanFlagSub = fbp.FlutterBluePlus.isScanning.listen((s) {
      _isScanning = s;
      notifyListeners();
    });

    try {
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (_) {}
  }

  bool _looksSupported(ScanResult r) {
    final name = (r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName)
        .toLowerCase();

    if (name.isNotEmpty && _nameKeys.any((k) => name.contains(k))) return true;

    for (final g in r.advertisementData.serviceUuids) {
      final s = g.str.toLowerCase();
      final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
      if (_svcTails.contains(tail)) return true;
    }

    // Xiaomi Mi Body + 0x181B (Body Composition)
    final isXiaomi = r.advertisementData.manufacturerData.keys.contains(0x0157);
    final hasBody = r.advertisementData.serviceUuids.any((g) => g.str.toLowerCase().endsWith('181b'));
    if (isXiaomi && hasBody) return true;

    return false;
    }

  void _enqueue(BluetoothDevice d) {
    final id = d.remoteId.str;
    if (_autoQ.contains(id)) return;
    _autoQ.add(id);
    _drainAutoQ();
  }

  Future<void> _drainAutoQ() async {
    if (_autoBusy) return;
    _autoBusy = true;
    try {
      while (_autoQ.isNotEmpty) {
        final id = _autoQ.removeFirst();
        final dev = BluetoothDevice.fromId(id);

        final wasScanning = _isScanning;
        try {
          if (wasScanning) {
            try { await fbp.FlutterBluePlus.stopScan(); } catch (_) {}
          }
          await dev.connect(autoConnect: false, timeout: const Duration(seconds: 12));
          // ถ้าเชื่อมต่อได้ ค่อยเริ่ม session
          await _createAndStartSession(dev);
        } catch (_) {
          // เงียบไว้ (รอคูลดาวน์แล้วลองใหม่จากสแกนรอบหน้า)
        } finally {
          if (wasScanning) _startScanOnce();
        }

        await Future.delayed(const Duration(milliseconds: 250));
      }
    } finally {
      _autoBusy = false;
    }
  }

  // ---------- map latestData -> Vitals ----------
  void _applySessionToVitals(DeviceSession s) {
    final m = s.latestData;
    if (m.isEmpty) return;

    int? _asInt(String? v) => v == null ? null : int.tryParse(v.trim());
    double? _asDouble(String? v) => v == null ? null : double.tryParse(v.trim());
    bool _in(int x, int lo, int hi) => x >= lo && x <= hi;
    bool _inD(double x, double lo, double hi) => x >= lo && x <= hi;

    final sys = _asInt(m['sys'] ?? m['systolic']);
    final dia = _asInt(m['dia'] ?? m['diastolic']);
    if (sys != null && dia != null && _in(sys, 60, 260) && _in(dia, 30, 200)) {
      Vitals.I.putBp(sys: sys, dia: dia);
    }

    final pr = _asInt(m['pul'] ?? m['PR'] ?? m['pr'] ?? m['pulse']);
    if (pr != null && _in(pr, 30, 250)) {
      Vitals.I.putPr(pr);
    }

    final spo2 = _asInt(m['spo2'] ?? m['SpO2'] ?? m['SPO2']);
    if (spo2 != null && _in(spo2, 70, 100)) {
      Vitals.I.putSpo2(spo2);
    }

    final src = (m['src'] ?? '').toLowerCase();
    final temp = _asDouble(m['temp'] ?? m['temp_c']);
    if (temp != null && !src.contains('yx110') && _inD(temp, 30.0, 45.0)) {
      Vitals.I.putBt(temp);
    }

    final mgdl = _asDouble(m['mgdl'] ?? m['mgdL']);
    if (mgdl != null && _inD(mgdl, 10, 1000)) {
      Vitals.I.putDtx(mgdl);
    }

    final bw = _asDouble(m['weight_kg'] ?? m['weight'] ?? m['bw']);
    if (bw != null && _inD(bw, 1, 400)) {
      Vitals.I.putBw(bw);
    }

    final h = _asDouble(m['height_cm'] ?? m['h']);
    if (h != null && _inD(h, 30, 250)) {
      Vitals.I.putH(h);
    }
  }

  // ---------- misc ----------
  int get connectedCount => _sessions.length;
  bool get isScanning => _isScanning;

  Future<void> disposeHub() async {
    _poll?.cancel(); _poll = null;
    _scanTimer?.cancel(); _scanTimer = null;
    await _scanSub?.cancel(); _scanSub = null;
    await _scanFlagSub?.cancel(); _scanFlagSub = null;

    for (final s in _sessions.values) { await s.dispose(); }
    _sessions.clear();
  }
}
