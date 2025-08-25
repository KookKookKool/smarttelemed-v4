// lib/core/device/device_hub.dart
import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttelemed_v4/core/device/vitals.dart';

// parsers
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_yhw_6.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_bp_ye680a.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_glucose.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_po_jpd_500f.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_ha120.dart';
import 'package:smarttelemed_v4/core/device/add_device/Mi/mibfs_05hm.dart';
import 'package:smarttelemed_v4/core/device/add_device/Beurer/beurer_tem_ft95.dart';
import 'package:smarttelemed_v4/core/device/add_device/Beurer/beurer_bm57.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_bfs710.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_fr400.dart';

class DeviceHub with ChangeNotifier {
  DeviceHub._();
  static final DeviceHub I = DeviceHub._();

  // ---------- settings ----------
  // สแกนทุก 8 วินาที ถ้าไม่ได้สแกนอยู่
  static const scanInterval = Duration(seconds: 8);
  // ต่ออัตโนมัติ “เฉพาะ” อุปกรณ์ที่บันทึกไว้ (ปลอดภัยสุด)
  static const bool autoSupportedToo = false;

  bool _started = false;

  // scan state
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  bool _isScanning = false;
  Timer? _rescanTimer;

  // known devices (จากโฆษณา BLE)
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, bool> _supportedMap = {};

  // เชื่อมต่อ
  final Map<String, _HubSession> _sessions = {};
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connSubs = {};
  final Set<String> _connectingIds = {};
  final Set<String> _connectedIds  = {};

  // auto-connect
  final Queue<String> _autoQueue = Queue<String>();
  bool _autoConnecting = false;

  // installed (ของฉัน)
  Set<String> _installedIds = {};

  // --- GUIDs / ช่วยจับรุ่น ---
  static final Guid haChrFff1 = Guid('0000fff1-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid haChrFff2 = Guid('0000fff2-0000-1000-8000-00805f9b34fb'); // write/wwr

  static final Guid svcBp      = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid chrBpMeas  = Guid('00002a35-0000-1000-8000-00805f9b34fb');

  static final Guid svcThermo  = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid chrTemp    = Guid('00002a1c-0000-1000-8000-00805f9b34fb');

  static final Guid svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluRacp = Guid('00002a52-0000-1000-8000-00805f9b34fb');

  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');

  static final Guid svcBody   = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid chrBodyMx = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  static final Guid chr1530   = Guid('00001530-0000-3512-2118-0009af100700');
  static final Guid chr1531   = Guid('00001531-0000-3512-2118-0009af100700');
  static final Guid chr1532   = Guid('00001532-0000-3512-2118-0009af100700');
  static final Guid chr1542   = Guid('00001542-0000-3512-2118-0009af100700');
  static final Guid chr1543   = Guid('00001543-0000-3512-2118-0009af100700');
  static final Guid chr2A2Fv  = Guid('00002a2f-0000-3512-2118-0009af100700');

  static final Guid chrCde81  = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');
  static final Guid svcFfb0   = Guid('0000ffb0-0000-1000-8000-00805f9b34fb');
  static final Guid svcFee0   = Guid('0000fee0-0000-1000-8000-00805f9b34fb');
  static final Guid svcFff0   = Guid('0000fff0-0000-1000-8000-00805f9b34fb');

  static const Set<String> _supportedNameKeys = {
    'oximeter','my oximeter','jumper','jpd',
    'yuwell','ua-651','ua651','ye680a',
    'glucose','mibfs','scale','bfs','swan',
    'thermometer','fr400','fr-400','jpd-fr400','jpd fr400','ft95',
  };

  static const Set<String> _supportedServiceTails = {
    'cb80','1822','1810','1809','1808','181b','ffe0','ffb0','fee0','fff0',
  };

  // ================= API =================
  Future<void> ensureStarted() async {
    if (_started) return;
    _started = true;

    await _requestPerms();
    await Vitals.I.ensure();
    await _loadInstalledIds();

    // เริ่มดูรายชื่อที่ “เชื่อมต่อแล้ว” เพื่อเปิด session ให้ครบ
    await _refreshConnected();

    // ตั้ง loop สแกน (เบา ๆ)
    _rescanTimer = Timer.periodic(scanInterval, (_) {
      if (!_isScanning) _startScan();
    });

    // เฝ้าสถานะสแกน
    _isScanningSub = FlutterBluePlus.isScanning.listen((s) {
      _isScanning = s;
    });
  }

  Future<void> stop() async {
    await _stopScan();
    await _isScanningSub?.cancel(); _isScanningSub = null;
    _rescanTimer?.cancel(); _rescanTimer = null;
    for (final s in _sessions.values) { await s.dispose(); }
    _sessions.clear();
    for (final s in _connSubs.values) { await s.cancel(); }
    _connSubs.clear();
    _devices.clear(); _lastSeen.clear(); _supportedMap.clear();
    _connectingIds.clear(); _connectedIds.clear();
    _autoQueue.clear(); _autoConnecting = false;
    _started = false;
    notifyListeners();
  }

  // ใช้ตอนผู้ใช้เชื่อมต่อสำเร็จครั้งแรก (หรืออยาก “บันทึกเป็นของฉัน”)
  Future<void> markInstalled(String id) async {
    _installedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('installed_device_ids', _installedIds.toList());
  }

  Future<void> unmarkInstalled(String id) async {
    _installedIds.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('installed_device_ids', _installedIds.toList());
  }

  // ================= internals =================
  Future<void> _requestPerms() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();
    }
  }

  Future<void> _loadInstalledIds() async {
    final prefs = await SharedPreferences.getInstance();
    _installedIds = (prefs.getStringList('installed_device_ids') ?? []).toSet();
  }

  // ===== 1) refresh อุปกรณ์ที่ "เชื่อมต่อแล้ว" → เปิด session ถ้ายังไม่มี =====
  Future<void> _refreshConnected() async {
    try {
      final devs = await FlutterBluePlus.connectedDevices;

      // add new sessions
      for (final d in devs) {
        if (!_sessions.containsKey(d.remoteId.str)) {
          await _createAndStartSession(d);
        }
      }

      // remove gone
      final alive = devs.map((e) => e.remoteId.str).toSet();
      final gone = _sessions.keys.where((k) => !alive.contains(k)).toList();
      for (final id in gone) {
        await _sessions[id]?.dispose();
        _sessions.remove(id);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[DeviceHub] refreshConnected error: $e');
    }
  }

  // ===== 2) scan วนเบา ๆ และต่ออัตโนมัติ =====
  void _startScan() async {
    await _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final now = DateTime.now();
      for (final r in results) {
        final id = r.device.remoteId.str;
        _devices[id] = r.device;
        _lastSeen[id] = now;
        _supportedMap[id] = _matchSupported(r);

        // ต่ออัตโนมัติถ้าเป็นอุปกรณ์ที่บันทึกไว้ (หรือรุ่นที่รองรับถ้าตั้งค่า)
        if (_installedIds.contains(id) ||
            (autoSupportedToo && (_supportedMap[id] ?? false))) {
          _queueAutoConnect(id);
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[DeviceHub] startScan error: $e');
    }
  }

  Future<void> _stopScan() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
    await _scanSub?.cancel(); _scanSub = null;
  }

  bool _matchSupported(ScanResult r) {
    // ชื่อ
    final name = (r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName)
        .toLowerCase();
    if (name.isNotEmpty) {
      for (final k in _supportedNameKeys) {
        if (name.contains(k)) return true;
      }
    }
    // service uuid tails
    for (final g in r.advertisementData.serviceUuids) {
      final s = g.str.toLowerCase();
      final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
      if (_supportedServiceTails.contains(tail)) return true;
    }
    // Xiaomi scale hints
    final isXiaomi = r.advertisementData.manufacturerData.keys.contains(0x0157);
    final looksLikeScale = name.contains('mibfs') || name.contains('scale');
    bool _hasTail(Iterable<Guid> gs, String tail4) {
      final t = tail4.toLowerCase();
      for (final g in gs) {
        final s = g.str.toLowerCase();
        final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
        if (tail == t) return true;
      }
      return false;
    }
    final hasBodyComp = _hasTail(r.advertisementData.serviceUuids, '181b') ||
                        _hasTail(r.advertisementData.serviceData.keys, '181b');
    final hasMiBeacon = _hasTail(r.advertisementData.serviceData.keys, 'fe95');
    if (isXiaomi && (hasBodyComp || hasMiBeacon || looksLikeScale)) return true;

    // FR400 special
    if (r.advertisementData.manufacturerData.keys.contains(0xC11C)) return true;

    return false;
  }

  void _queueAutoConnect(String id) {
    if (_connectingIds.contains(id) || _connectedIds.contains(id) || _autoQueue.contains(id)) return;
    _autoQueue.add(id);
    _drainAutoQueue();
  }

  Future<void> _drainAutoQueue() async {
    if (_autoConnecting) return;
    _autoConnecting = true;
    try {
      while (_autoQueue.isNotEmpty) {
        final id = _autoQueue.removeFirst();
        final dev = _devices[id];
        if (dev == null) continue;
        if (_connectedIds.contains(id)) continue;
        try {
          await _connectTo(dev);
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e) {
          debugPrint('[DeviceHub] autoConnect $id error: $e');
        }
      }
    } finally {
      _autoConnecting = false;
    }
  }

  void _watchDevice(BluetoothDevice d) {
    final id = d.remoteId.str;
    if (_connSubs.containsKey(id)) return;
    _connSubs[id] = d.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.connected) {
        _connectedIds.add(id);
        notifyListeners();
      } else if (s == BluetoothConnectionState.disconnected) {
        _connectedIds.remove(id);
        // cleanup session
        final ses = _sessions.remove(id);
        if (ses != null) await ses.dispose();
        notifyListeners();
      }
    });
  }

  Future<void> _connectTo(BluetoothDevice d) async {
    final id = d.remoteId.str;
    _watchDevice(d);

    // เลี่ยงชน GATT: หยุดสแกนชั่วคราว
    final wasScanning = _isScanning;
    await _stopScan();

    _connectingIds.add(id);
    try {
      await d.connect(autoConnect: false, timeout: const Duration(seconds: 12));
      await markInstalled(id); // บันทึกเป็น "ของฉัน" เมื่อสำเร็จ
      await _createAndStartSession(d);
    } catch (e) {
      debugPrint('[DeviceHub] connect error: $e');
    } finally {
      _connectingIds.remove(id);
      if (wasScanning) _startScan();
    }
  }

  Future<void> _createAndStartSession(BluetoothDevice d) async {
    final session = _HubSession(
      device: d,
      onUpdate: () => notifyListeners(),
      onError: (e) => debugPrint('[DeviceHub] ${d.platformName}: $e'),
      onDisconnected: () async => _refreshConnected(),
    );
    _sessions[d.remoteId.str] = session;
    await session.start(pickParser: (dev, svcs) => _pickParser(dev, svcs));
  }

  // ===== เลือก parser / binding =====
  Future<_ParserBinding> _pickParser(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    bool hasSvc(Guid svc) => services.any((s) => s.uuid == svc);
    bool hasSvcTail(String tail4) {
      final t = tail4.toLowerCase();
      return services.any((s) {
        final u = s.uuid.str.toLowerCase();
        final tail = u.length >= 4 ? u.substring(u.length - 4) : u;
        return tail == t;
      });
    }
    bool hasChr(Guid svc, Guid chr) {
      final s = services.where((x) => x.uuid == svc);
      if (s.isEmpty) return false;
      return s.first.characteristics.any((c) => c.uuid == chr);
    }
    bool hasAnyChr(Guid chr) {
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.uuid == chr) return true;
        }
      }
      return false;
    }

    final name = device.platformName.toLowerCase();

    // ---- HA120 มาก่อนเสมอ ----
    if (name.contains('ha120') || name.contains('jpd-ha120') ||
        hasSvcTail('af30') ||
        (hasSvc(svcFff0) && (hasChr(svcFff0, haChrFff1) || hasChr(svcFff0, haChrFff2)))) {
      final s = await JumperJpdHa120(device: device).parse();
      return _ParserBinding.map(s);
    }

    // ---- FR400 ต้องมีชื่อชัดเจน ไม่ใช้ FFF0 อย่างเดียว ----
    if ((name.contains('fr400') || name.contains('jpd-fr400')) && hasSvc(svcFff0)) {
      final hasStdThermo = hasSvc(svcThermo) && hasChr(svcThermo, chrTemp);
      if (!hasStdThermo) {
        final fr = JumperFr400(device: device);
        await fr.start();
        return _ParserBinding.temp(fr.onTemperature, cleanup: fr.dispose);
      }
    }

    // Jumper oximeter
    if (hasAnyChr(chrCde81)) {
      final s = await JumperPoJpd500f(device: device).parse();
      return _ParserBinding.map(s);
    }

    // Yuwell BP YE680A (vendor stream)
    if (name.contains('ye680a') || name.contains('ye680')) {
      final s = await YuwellBpYe680a(device: device).parse();
      return _ParserBinding.map(s);
    }

    // BP มาตรฐาน
    if (hasSvc(svcBp) && hasChr(svcBp, chrBpMeas)) {
      final s = await AdUa651Ble(device: device).parse();
      return _ParserBinding.bp(s);
    }

    // Thermometer มาตรฐาน
    if (hasSvc(svcThermo) && hasChr(svcThermo, chrTemp)) {
      final s = await YuwellYhw6(device: device).parse();
      return _ParserBinding.temp(s);
    }

    if (hasSvc(svcGlucose) &&
      hasChr(svcGlucose, chrGluMeas) &&
      hasChr(svcGlucose, chrGluRacp)) {
    final mgStream = YuwellGlucose(device: device).parse(fetchLastOnly: true); // Stream<String>
    final mapStream = mgStream.map<Map<String,String>>((mg) => {'mgdl': mg});
    return _ParserBinding.map(mapStream);
    }


    // Yuwell oximeter (FFE0/FFE4)
    if (hasSvc(svcFfe0) && hasChr(svcFfe0, chrFfe4)) {
      final s = await YuwellFpoYx110(device: device).parse();
      return _ParserBinding.map(s);
    }

    // Mi Body Scale
    if (hasSvc(svcBody) || hasChr(svcBody, chrBodyMx) ||
        hasAnyChr(chr1530) || hasAnyChr(chr1531) ||
        hasAnyChr(chr1532) || hasAnyChr(chr1542) ||
        hasAnyChr(chr1543) || hasAnyChr(chr2A2Fv)) {
      final s = await MiBfs05hm(device: device).parse();
      return _ParserBinding.map(s);
    }

    // Beurer FT95
    if (name.contains('ft95') && hasSvc(svcThermo) && hasChr(svcThermo, chrTemp)) {
      final beurer = BeurerFt95(device: device);
      await beurer.connect();
      return _ParserBinding.temp(beurer.onTemperature);
    }

    // Beurer BM57
    if (name.contains('bm57') && hasSvc(svcBp) && hasChr(svcBp, chrBpMeas)) {
      final b = BeurerBm57(device: device);
      await b.start();
      return _ParserBinding.map(b.onBloodPressure);
    }

    // Jumper BFS-710
    if (hasSvc(svcFfb0) || hasSvc(svcFee0) || name.contains('bfs') || name.contains('swan')) {
      final bfs = JumperJpdBfs710(device: device, enableLog: false);
      await bfs.start();
      final weightStream = bfs.onWeightKg.map((kg) => {'weight_kg': kg.toStringAsFixed(1)});
      return _ParserBinding.map(weightStream, cleanup: bfs.stop);
    }

    throw Exception('ยังไม่รองรับอุปกรณ์นี้');
  }
}

// =============== session ภายใน Hub (ดันค่าเข้า Vitals) ===============
class _HubSession {
  _HubSession({
    required this.device,
    required this.onUpdate,
    required this.onError,
    required this.onDisconnected,
  });

  final BluetoothDevice device;
  final VoidCallback onUpdate;
  final void Function(Object error) onError;
  final Future<void> Function() onDisconnected;

  StreamSubscription? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Future<void> Function()? _cleanup;

  Future<void> start({
    required Future<_ParserBinding> Function(BluetoothDevice device, List<BluetoothService> services) pickParser,
  }) async {
    _connSub = device.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.disconnected) {
        await _cleanupBinding();
        onUpdate();
        await onDisconnected();
      }
    });

    try {
      try { await FlutterBluePlus.stopScan(); } catch (_) {}
      var st = await device.connectionState.first;
      if (st == BluetoothConnectionState.disconnected) {
        await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
        st = await device.connectionState
            .where((x) => x == BluetoothConnectionState.connected || x == BluetoothConnectionState.disconnected)
            .first
            .timeout(const Duration(seconds: 12));
        if (st != BluetoothConnectionState.connected) throw 'เชื่อมต่อไม่สำเร็จ';
      }

      final services = await device.discoverServices();

      await _cleanupBinding();
      final binding = await pickParser(device, services);
      _cleanup = binding.cleanup;

      _dataSub = binding.mapStream?.listen((m) async {
        // map → Vitals
        await Vitals.I.ensure();

        int? _i(String? s){ if(s==null) return null; return int.tryParse(s.replaceAll(RegExp(r'[^0-9-]'), '')); }
        double? _d(String? s){ if(s==null) return null; return double.tryParse(s.replaceAll(',', '.')); }

        final sys = _i(m['sys'] ?? m['systolic']);
        final dia = _i(m['dia'] ?? m['diastolic']);
        final pul = _i(m['pul'] ?? m['pulse'] ?? m['pr'] ?? m['PR']);
        if (sys != null && dia != null) await Vitals.I.putBp(sys: sys, dia: dia, fromDevice: true);
        if (pul != null) await Vitals.I.putPr(pul, fromDevice: true);

        final spo2 = _i(m['spo2'] ?? m['SpO2'] ?? m['SPO2'] ?? m['oxygen']);
        if (spo2 != null) await Vitals.I.putSpo2(spo2, fromDevice: true);

        final t = _d(m['temp'] ?? m['temp_c']);
        if (t != null && t > 0) await Vitals.I.putBt(double.parse(t.toStringAsFixed(2)), fromDevice: true);

        final kg = _d(m['weight_kg'] ?? m['kg'] ?? m['weight']);
        if (kg != null && kg > 0) await Vitals.I.putBw(double.parse(kg.toStringAsFixed(2)), fromDevice: true);

        final mg = _d(m['mgdl'] ?? m['mg/dl'] ?? m['mg%']);
        if (mg != null) await Vitals.I.putDtx(mg, fromDevice: true);

        onUpdate();
      }, onError: (e) { onError(e); onUpdate(); });

      _dataSub ??= binding.bpStream?.listen((bp) async {
        await Vitals.I.ensure();
        await Vitals.I.putBp(
          sys: bp.systolic.toInt(),
          dia: bp.diastolic.toInt(),
          pulse: bp.pulse?.toInt(),
          fromDevice: true,
        );
        onUpdate();
      }, onError: (e) { onError(e); onUpdate(); });

      _dataSub ??= binding.tempStream?.listen((t) async {
        await Vitals.I.ensure();
        await Vitals.I.putBt(double.parse(t.toStringAsFixed(2)), fromDevice: true);
        onUpdate();
      }, onError: (e) { onError(e); onUpdate(); });

    } catch (e) {
      onError(e); onUpdate();
    }
  }

  Future<void> _cleanupBinding() async {
    await _dataSub?.cancel(); _dataSub = null;
    if (_cleanup != null) { try { await _cleanup!(); } catch (_) {} _cleanup = null; }
  }

  Future<void> dispose() async {
    await _cleanupBinding();
    await _connSub?.cancel();
  }
}

// ===== binding กลาง =====
class _ParserBinding {
  _ParserBinding._({this.mapStream, this.bpStream, this.tempStream, this.cleanup});
  final Stream<Map<String, String>>? mapStream;
  final Stream<BpReading>? bpStream;
  final Stream<double>? tempStream;
  final Future<void> Function()? cleanup;

  static _ParserBinding map(Stream<Map<String, String>> s, {Future<void> Function()? cleanup}) =>
      _ParserBinding._(mapStream: s, cleanup: cleanup);
  static _ParserBinding bp(Stream<BpReading> s, {Future<void> Function()? cleanup}) =>
      _ParserBinding._(bpStream: s, cleanup: cleanup);
  static _ParserBinding temp(Stream<double> s, {Future<void> Function()? cleanup}) =>
      _ParserBinding._(tempStream: s, cleanup: cleanup);
}
