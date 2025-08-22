// lib/core/device/device_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_bp_ye680a.dart';

// ไปหน้าเชื่อมต่อ/หน้าเดี่ยว
import 'package:smarttelemed_v4/core/device/device_connect.dart';
import 'package:smarttelemed_v4/core/device/device_page.dart';

// parsers อื่น ๆ
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_yhw_6.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_glucose.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_po_jpd_500f.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_ha120.dart';
import 'package:smarttelemed_v4/core/device/add_device/Mi/mibfs_05hm.dart';
import 'package:smarttelemed_v4/core/device/add_device/Beurer/beurer_tem_ft95.dart';
import 'package:smarttelemed_v4/core/device/add_device/Beurer/beurer_bm57.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_bfs710.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_fr400.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final Map<String, _DeviceSession> _sessions = {};
  bool _loading = false;

  // ตัวจับเวลาสำหรับดึงสถานะเชื่อมต่อซ้ำ ๆ
  Timer? _watchTimer;
  bool _refreshing = false;

  // ---- GUIDs ที่ใช้จำแนก ----
  static final Guid haChrFff1 = Guid('0000fff1-0000-1000-8000-00805f9b34fb'); // notify
static final Guid haChrFff2 = Guid('0000fff2-0000-1000-8000-00805f9b34fb'); // write/wwr
  // BP
  static final Guid svcBp      = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid chrBpMeas  = Guid('00002a35-0000-1000-8000-00805f9b34fb');
  // Thermometer
  static final Guid svcThermo  = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid chrTemp    = Guid('00002a1c-0000-1000-8000-00805f9b34fb');
  // Glucose
  static final Guid svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluRacp = Guid('00002a52-0000-1000-8000-00805f9b34fb');
  // Yuwell-like oximeter
  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');
  // Body Composition + Xiaomi proprietary
  static final Guid svcBody   = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid chrBodyMx = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  static final Guid chr1530   = Guid('00001530-0000-3512-2118-0009af100700');
  static final Guid chr1531   = Guid('00001531-0000-3512-2118-0009af100700');
  static final Guid chr1532   = Guid('00001532-0000-3512-2118-0009af100700');
  static final Guid chr1542   = Guid('00001542-0000-3512-2118-0009af100700');
  static final Guid chr1543   = Guid('00001543-0000-3512-2118-0009af100700');
  static final Guid chr2A2Fv  = Guid('00002a2f-0000-3512-2118-0009af100700');
  // Jumper oximeter (ล็อกเฉพาะ chr)
  static final Guid chrCde81  = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');
  // BFS-710 services
  static final Guid svcFfb0 = Guid('0000ffb0-0000-1000-8000-00805f9b34fb');
  static final Guid svcFee0 = Guid('0000fee0-0000-1000-8000-00805f9b34fb');
  // Vendor thermometer (Jumper FR400)
  static final Guid svcFff0  = Guid('0000fff0-0000-1000-8000-00805f9b34fb');

  @override
  void initState() {
    super.initState();
    _refreshConnected();
    _watchTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_refreshing) _refreshConnected();
    });
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    for (final s in _sessions.values) { s.dispose(); }
    super.dispose();
  }

  // ===== refresh รายชื่ออุปกรณ์ที่ "เชื่อมต่ออยู่" แล้วเริ่ม/หยุด session ตามจริง =====
  Future<void> _refreshConnected() async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) setState(() => _loading = true);

    try {
      final devs = await FlutterBluePlus.connectedDevices;

      // เพิ่ม session ให้ device ใหม่
      for (final d in devs) {
        if (!_sessions.containsKey(d.remoteId.str)) {
          await _createAndStartSession(d);
        }
      }

      // ลบ session ที่หายไปแล้ว
      final alive = devs.map((e) => e.remoteId.str).toSet();
      final gone = _sessions.keys.where((k) => !alive.contains(k)).toList();
      for (final id in gone) {
        await _sessions[id]?.dispose();
        _sessions.remove(id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดอุปกรณ์ที่เชื่อมต่อไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      _refreshing = false;
    }
  }

  Future<void> _createAndStartSession(BluetoothDevice d) async {
    final session = _DeviceSession(
      device: d,
      onUpdate: () => mounted ? setState(() {}) : null,
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${d.platformName.isNotEmpty ? d.platformName : d.remoteId.str}: $e')),
        );
      },
      onDisconnected: () async {
        await _refreshConnected();
      },
    );
    _sessions[d.remoteId.str] = session;
    await session.start(pickParser: (dev, svcs) => _pickParser(dev, svcs));
  }

  // ===== เลือก parser ตาม services/characteristics =====
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

   // --- HA120 ก่อน ---
    if (name.contains('ha120') || name.contains('jpd-ha120') ||
        (hasSvc(svcFff0) && (hasChr(svcFff0, haChrFff1) || hasChr(svcFff0, haChrFff2)))) {
      final s = await JumperJpdHa120(device: device).parse();
      return _ParserBinding.map(s);
    }

    // --- FR400 (ระบุด้วยชื่อเท่านั้น ป้องกันชน FFF0) ---
    if ((name.contains('fr400') || name.contains('jpd-fr400')) && hasSvc(svcFff0)) {
      final hasStdThermo = hasSvc(svcThermo) && hasChr(svcThermo, chrTemp);
      if (!hasStdThermo) {
        final fr = JumperFr400(device: device);
        await fr.start();
        return _ParserBinding.temp(fr.onTemperature, cleanup: fr.dispose);
      }
    }

    // --- Jumper oximeter: ล็อกเฉพาะ chrCde81 ---
    if (hasAnyChr(chrCde81)) {
      final s = await JumperPoJpd500f(device: device).parse();
      return _ParserBinding.map(s);
    }

    // --- BP ---
    if (hasSvc(svcBp) && hasChr(svcBp, chrBpMeas)) {
      final s = await AdUa651Ble(device: device).parse();
      return _ParserBinding.bp(s);
    }

    // --- Thermometer มาตรฐาน ---
    if (hasSvc(svcThermo) && hasChr(svcThermo, chrTemp)) {
      final s = await YuwellYhw6(device: device).parse();
      return _ParserBinding.temp(s);
    }

    // --- Glucose ---
    if (hasSvc(svcGlucose) && hasChr(svcGlucose, chrGluMeas) && hasChr(svcGlucose, chrGluRacp)) {
      final s = await YuwellGlucose(device: device).parse(fetchLastOnly: true, syncTime: true);
      return _ParserBinding.map(s);
    }

    // --- Yuwell oximeter (FFE0/FFE4) ---
    if (hasSvc(svcFfe0) && hasChr(svcFfe0, chrFfe4)) {
      final s = await YuwellFpoYx110(device: device).parse();
      return _ParserBinding.map(s);
    }

    // --- Mi Body Scale ---
    if (hasSvc(svcBody) ||
        hasChr(svcBody, chrBodyMx) ||
        hasAnyChr(chr1530) || hasAnyChr(chr1531) ||
        hasAnyChr(chr1532) || hasAnyChr(chr1542) ||
        hasAnyChr(chr1543) || hasAnyChr(chr2A2Fv)) {
      final s = await MiBfs05hm(device: device).parse();
      return _ParserBinding.map(s);
    }

    // --- Beurer FT95 ---
    if (name.contains('ft95') && hasSvc(svcThermo) && hasChr(svcThermo, chrTemp)) {
      final beurer = BeurerFt95(device: device);
      await beurer.connect();
      return _ParserBinding.temp(beurer.onTemperature);
    }

    // --- Beurer BM57 ---
    if (name.contains('bm57') && hasSvc(svcBp) && hasChr(svcBp, chrBpMeas)) {
      final b = BeurerBm57(device: device);
      await b.start();
      return _ParserBinding.map(b.onBloodPressure);
    }

    // --- Jumper BFS-710 (Body Scale) ---
    if (hasSvc(svcFfb0) || hasSvc(svcFee0) || name.contains('bfs') || name.contains('swan')) {
      final bfs = JumperJpdBfs710(device: device, enableLog: false);
      await bfs.start();

      // (12) Yuwell BP YE680A (BP service)
      // --- Yuwell BP YE680A (เวนเดอร์สตรีม) ---
      if (name.contains('ye680a') || name.contains('ye680')) {
        final s = await YuwellBpYe680a(device: device).parse();
        return _ParserBinding.map(s);
      }
      // --- BP มาตรฐาน (GATT 0x1810/0x2a35) ---
      if (hasSvc(svcBp) && hasChr(svcBp, chrBpMeas)) {
        final s = await AdUa651Ble(device: device).parse();
        return _ParserBinding.bp(s);
      }

      // stream น้ำหนักสำหรับ UI
      final weightStream = bfs.onWeightKg.map((kg) => {'weight_kg': kg.toStringAsFixed(1)});

      return _ParserBinding.map(
        weightStream,
        cleanup: bfs.stop,
      );
    }

    throw Exception('ยังไม่รองรับอุปกรณ์นี้ (ไม่พบ Service/Characteristic ที่รู้จัก)');
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final sessions = _sessions.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(
        title: const Text('อุปกรณ์ที่เชื่อมต่อ (ทั้งหมด)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConnected,
            tooltip: 'รีเฟรชอุปกรณ์ที่เชื่อมต่อ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeviceConnectPage()),
          );
          if (!mounted) return;
          await _refreshConnected();
        },
        icon: const Icon(Icons.add_link),
        label: const Text('เชื่อมต่ออุปกรณ์'),
      ),
      body: _loading && sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text('ยังไม่พบอุปกรณ์ที่เชื่อมต่อ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sessions.length,
                  itemBuilder: (_, i) => _DeviceCard(
                    session: sessions[i],
                    onOpen: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DevicePage(device: sessions[i].device)),
                      );
                    },
                    onDisconnect: () async {
                      await sessions[i].device.disconnect();
                      await _refreshConnected();
                    },
                  ),
                ),
    );
  }
}

// ===== การ์ดต่ออุปกรณ์ =====
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.session,
    required this.onOpen,
    required this.onDisconnect,
  });

  final _DeviceSession session;
  final VoidCallback onOpen;
  final VoidCallback onDisconnect;

  int? _tryInt(String? s) => s == null ? null : int.tryParse(s.trim());
  int? _validSpo2(String? s) {
    final n = _tryInt(s);
    if (n == null) return null;
    return (n >= 70 && n <= 100) ? n : null;
  }
  int? _validPr(String? s) {
    final n = _tryInt(s);
    if (n == null) return null;
    return (n >= 30 && n <= 250) ? n : null;
  }

  @override
  Widget build(BuildContext context) {
    final title = session.title;
    final id    = session.device.remoteId.str;
    final data  = session.latestData;
    final error = session.error;

    // ===== NEW: ดึงค่า BP =====
    final String? sys = data['sys'] ?? data['systolic'];
    final String? dia = data['dia'] ?? data['diastolic'];
    // pulse รองรับหลายคีย์ รวมถึง 'pul' (Jumper HA120)
    final String? bpPulse = data['pul'] ?? data['PR'] ?? data['pr'] ?? data['pulse'];

    int? _tryInt(String? s) => s == null ? null : int.tryParse(s.trim());
    int? _validSpo2(String? s) {
      final n = _tryInt(s); if (n == null) return null; return (n >= 70 && n <= 100) ? n : null;
    }
    int? _validPr(String? s) {
      final n = _tryInt(s); if (n == null) return null; return (n >= 30 && n <= 250) ? n : null;
    }

    // เดิม: SpO2/PR (อย่าดึง 'pul' มาคิดเป็น PR ในบล็อกนี้ เพื่อกันสับสนกับ BP)
    final spo2 = _validSpo2(data['spo2'] ?? data['SpO2'] ?? data['SPO2']);
    final pr   = _validPr (data['pr']   ?? data['PR']   ?? data['pulse']);

    final tempTxt = data['temp'] ?? data['temp_c'];
    final weight  = data['weight_kg'];
    final bmi     = data['bmi'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ... header เหมือนเดิม ...

          if (error != null) ...[
            Text('ผิดพลาด: $error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
          ],

          // ===== Weight =====
          if (weight != null) ...[
            const Text('Weight', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$weight kg', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            if (bmi != null) Text('BMI: $bmi', style: const TextStyle(fontSize: 16)),
          ],

          // ===== NEW: BP (มี SYS/DIA เมื่อไหร่ โชว์ทันที) =====
          if (weight == null && sys != null && dia != null) ...[
            const Divider(),
            const Text('Blood Pressure', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Row(
              children: [
                Text('$sys / $dia', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                const Text('mmHg'),
              ],
            ),
            if (bpPulse != null) ...[
              const SizedBox(height: 6),
              Text('Pulse: $bpPulse bpm', style: const TextStyle(fontSize: 16)),
            ],
          ],

          // ===== Temp (แสดงเมื่อยังไม่มี BP/Weight) =====
          if (weight == null && (sys == null || dia == null) && tempTxt != null && tempTxt.isNotEmpty) ...[
            const Divider(),
            const Text('Temperature', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$tempTxt °C', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],

          // ===== SpO2/PR (แสดงเมื่อยังไม่มี BP/Weight) =====
          if (weight == null && (sys == null || dia == null) && (spo2 != null || pr != null)) ...[
            const Divider(),
            Text('SpO₂: ${spo2?.toString() ?? '-'} %',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Pulse: ${pr?.toString() ?? '-'} bpm', style: const TextStyle(fontSize: 18)),
          ],

          if (weight == null && data.isEmpty) ...[
            const Divider(),
            const Text('ยังไม่มีข้อมูลจากอุปกรณ์'),
          ],
        ]),
      ),
    );
  }
}
// ===== session ต่ออุปกรณ์ =====
class _DeviceSession {
  _DeviceSession({
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

  // cleanup พิเศษของ parser (เช่น stop()/dispose())
  Future<void> Function()? _cleanup;

  Map<String, String> latestData = {};
  String? error;

  String get title =>
      device.platformName.isNotEmpty ? device.platformName : device.remoteId.str;

  Future<void> start({
    required Future<_ParserBinding> Function(
      BluetoothDevice device,
      List<BluetoothService> services,
    ) pickParser,
  }) async {
    // เฝ้าตัดการเชื่อมต่อ
    _connSub = device.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.disconnected) {
        await _cleanupBinding();
        latestData = {};
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
        if (st != BluetoothConnectionState.connected) {
          throw 'เชื่อมต่อไม่สำเร็จ';
        }
      }

      final services = await device.discoverServices();

      await _cleanupBinding();
      final binding = await pickParser(device, services);
      _cleanup = binding.cleanup;

      _dataSub = binding.mapStream?.listen((m) {
        latestData = m;
        error = null;
        onUpdate();
      }, onError: (e) {
        error = '$e';
        onError(e);
        onUpdate();
      });

      _dataSub ??= binding.bpStream?.listen((bp) {
        latestData = {
          'sys': bp.systolic.toStringAsFixed(0),
          'dia': bp.diastolic.toStringAsFixed(0),
          'map': bp.map.toStringAsFixed(0),
          if (bp.pulse != null) 'pul': bp.pulse!.toStringAsFixed(0),
          if (bp.timestamp != null) 'ts': bp.timestamp!.toIso8601String(),
        };
        error = null;
        onUpdate();
      }, onError: (e) {
        error = '$e';
        onError(e);
        onUpdate();
      });

      _dataSub ??= binding.tempStream?.listen((t) {
        latestData = {'temp': t.toStringAsFixed(2)};
        error = null;
        onUpdate();
      }, onError: (e) {
        error = '$e';
        onError(e);
        onUpdate();
      });
    } catch (e) {
      error = '$e';
      onError(e);
      onUpdate();
    }
  }

  Future<void> _cleanupBinding() async {
    await _dataSub?.cancel(); _dataSub = null;
    if (_cleanup != null) {
      try { await _cleanup!(); } catch (_) {}
      _cleanup = null;
    }
  }

  Future<void> dispose() async {
    await _cleanupBinding();
    await _connSub?.cancel();
  }
}

// ===== binding กลาง =====
class _ParserBinding {
  _ParserBinding._({
    this.mapStream,
    this.bpStream,
    this.tempStream,
    this.cleanup,
  });

  final Stream<Map<String, String>>? mapStream;
  final Stream<BpReading>? bpStream;
  final Stream<double>? tempStream;
  final Future<void> Function()? cleanup;

  static _ParserBinding map(
    Stream<Map<String, String>> s, {
    Future<void> Function()? cleanup,
  }) =>
      _ParserBinding._(
        mapStream: s,
        cleanup: cleanup,
      );

  static _ParserBinding bp(
    Stream<BpReading> s, {
    Future<void> Function()? cleanup,
  }) =>
      _ParserBinding._(
        bpStream: s,
        cleanup: cleanup,
      );

  static _ParserBinding temp(
    Stream<double> s, {
    Future<void> Function()? cleanup,
  }) =>
      _ParserBinding._(
        tempStream: s,
        cleanup: cleanup,
      );

  Future<void> dispose() async {
    try {
      if (cleanup != null) await cleanup!();
    } catch (_) {}
  }
}
