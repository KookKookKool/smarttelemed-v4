// lib/core/device/device_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

// ไปหน้าเชื่อมต่อ/หน้าเดี่ยว
import 'package:smarttelemed_v4/core/device/device_connect.dart';
import 'package:smarttelemed_v4/core/device/device_page.dart';

// parsers
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_yhw_6.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_glucose.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_po_jpd_500f.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_ha120.dart';
import 'package:smarttelemed_v4/core/device/add_device/Mi/mibfs_05hm.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final Map<String, _DeviceSession> _sessions = {};
  bool _loading = false;

  // ---- GUIDs ----
  // BP
  static final Guid svcBp      = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid chrBpMeas  = Guid('00002a35-0000-1000-8000-00805f9b34fb');
  // Thermometer
  static final Guid svcThermo  = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid chrTemp    = Guid('00002a1c-0000-1000-8000-00805f9b34fb');
  // Glucose
  static final Guid svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluRacp = Guid('00002a52-0000-1000-8000-00805f9b34fb'); // ← เพิ่มบรรทัดนี้
  // Yuwell-like oximeter
  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');
  // Body Composition (มาตรฐาน) + Xiaomi proprietary
  static final Guid svcBody   = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid chrBodyMx = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  static final Guid chr1530   = Guid('00001530-0000-3512-2118-0009af100700'); // weight(หลัก)
  static final Guid chr1531   = Guid('00001531-0000-3512-2118-0009af100700'); // alt
  static final Guid chr1532   = Guid('00001532-0000-3512-2118-0009af100700'); // kickoff
  static final Guid chr1542   = Guid('00001542-0000-3512-2118-0009af100700'); // alt
  static final Guid chr1543   = Guid('00001543-0000-3512-2118-0009af100700'); // alt
  static final Guid chr2A2Fv  = Guid('00002a2f-0000-3512-2118-0009af100700'); // vendor alt

  // Jumper oximeter (ล็อกเฉพาะ chr)
  static final Guid chrCde81   = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');

  @override
  void initState() {
    super.initState();
    _refreshConnected();
  }

  @override
  void dispose() {
    for (final s in _sessions.values) { s.dispose(); }
    super.dispose();
  }

  // ===== refresh รายชื่ออุปกรณ์ที่ "เชื่อมต่ออยู่" แล้วเริ่ม session =====
  Future<void> _refreshConnected() async {
    setState(() => _loading = true);
    try {
      final devs = await FlutterBluePlus.connectedDevices;
      for (final d in devs) {
        if (!_sessions.containsKey(d.remoteId.str)) {
          await _createAndStartSession(d);
        }
      }
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
    }
  }

  Future<void> _createAndStartSession(BluetoothDevice d) async {
    final session = _DeviceSession(
      device: d,
      onUpdate: () => setState(() {}),
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${d.platformName.isNotEmpty ? d.platformName : d.remoteId.str}: $e')),
        );
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

    // --- Jumper JPD-HA120 (BP: AF30 / FFF0) ---
    if (name.contains('ha120') || name.contains('jpd-ha120') || hasSvcTail('af30') || hasSvcTail('fff0')) {
      final s = await JumperJpdHa120(device: device).parse();
      return _ParserBinding.map(s);
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

    // --- Thermometer ---
    if (hasSvc(svcThermo) && hasChr(svcThermo, chrTemp)) {
      final s = await YuwellYhw6(device: device).parse();
      return _ParserBinding.temp(s);
    }

    // --- Glucose ---
    if (hasSvc(svcGlucose) &&
        hasChr(svcGlucose, chrGluMeas) &&
        hasChr(svcGlucose, chrGluRacp)) {
      final s = await YuwellGlucose(device: device)
          .parse(fetchLastOnly: true, syncTime: true);
      return _ParserBinding.map(s);
    }

    // --- Yuwell oximeter (FFE0/FFE4) ---
    if (hasSvc(svcFfe0) && hasChr(svcFfe0, chrFfe4)) {
      final s = await YuwellFpoYx110(device: device).parse();
      return _ParserBinding.map(s);
    }

    // --- Mi Body Scale (BCS 0x181B หรือ proprietary 0x1530/0x1531/0x1532/0x1542/0x1543/0x2A2F) ---
    if (hasSvc(svcBody) ||
        hasChr(svcBody, chrBodyMx) ||
        hasAnyChr(chr1530) || hasAnyChr(chr1531) ||
        hasAnyChr(chr1532) || hasAnyChr(chr1542) ||
        hasAnyChr(chr1543) || hasAnyChr(chr2A2Fv)) {
      final s = await MiBfs05hm(device: device).parse(); // ใช้ 1530 เป็นหลัก + fallback อื่น ๆ
      return _ParserBinding.map(s);
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
                    },
                  ),
                ),
    );
  }
}

// ===== การ์ดแสดงผลต่ออุปกรณ์ =====
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

    final spo2 = _validSpo2(data['spo2'] ?? data['SpO2'] ?? data['SPO2']);
    final pr   = _validPr (data['pr']   ?? data['PR']   ?? data['pulse']);
    final tempTxt = data['temp'] ?? data['temp_c'];

    final weight = data['weight_kg'];   // ✅ น้ำหนักจาก MiBfs05hm
    final bmi    = data['bmi'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.devices),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onOpen, child: const Text('เปิด')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onDisconnect, child: const Text('ตัดการเชื่อมต่อ')),
            ],
          ),
          const SizedBox(height: 4),
          Text('ID: $id', style: const TextStyle(color: Colors.black54)),
          const Divider(),

          if (error != null) ...[
            Text('ผิดพลาด: $error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
          ],

          // ✅ น้ำหนัก (MiBFS)
          if (weight != null) ...[
            Text('Weight', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$weight kg', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            if (bmi != null) Text('BMI: $bmi', style: const TextStyle(fontSize: 16)),
            const Divider(),
          ],

          if (tempTxt != null && tempTxt.isNotEmpty) ...[
            Text('Temperature', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$tempTxt °C', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
          ],

          if (spo2 != null || pr != null) ...[
            Text('SpO₂: ${spo2?.toString() ?? '-'} %',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Pulse: ${pr?.toString() ?? '-'} bpm', style: const TextStyle(fontSize: 18)),
            const Divider(),
          ],

          if (data.isEmpty)
            const Text('ยังไม่มีข้อมูลจากอุปกรณ์')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries
                  .where((e) => !{
                        'weight_kg','bmi','impedance_ohm','src','raw',
                        'spo2','SpO2','SPO2',
                        'pr','PR','pulse',
                        'temp','temp_c',
                      }.contains(e.key))
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
            ),

          // debug fields (ถ้ามี)
          if (data['src'] != null) Text('src: ${data['src']}', style: const TextStyle(fontSize: 12)),
          if (data['raw'] != null) Text('raw: ${data['raw']}', style: const TextStyle(fontSize: 12)),
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
  });

  final BluetoothDevice device;
  final VoidCallback onUpdate;
  final void Function(Object error) onError;

  StreamSubscription? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

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
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        latestData = {};
        onUpdate();
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
      final binding = await pickParser(device, services);

      await _dataSub?.cancel();
      _dataSub = binding.listen(
        onMap: (m) {
          latestData = m;
          error = null;
          onUpdate();
        },
        onBp: (bp) {
          latestData = {
            'sys': bp.systolic.toStringAsFixed(0),
            'dia': bp.diastolic.toStringAsFixed(0),
            'map': bp.map.toStringAsFixed(0),
            if (bp.pulse != null) 'pul': bp.pulse!.toStringAsFixed(0),
            if (bp.timestamp != null) 'ts': bp.timestamp!.toIso8601String(),
          };
          error = null;
          onUpdate();
        },
        onTempC: (t) {
          latestData = {'temp': t.toStringAsFixed(2)};
          error = null;
          onUpdate();
        },
        onError: (e) {
          error = '$e';
          onError(e);
          onUpdate();
        },
      );
    } catch (e) {
      error = '$e';
      onError(e);
      onUpdate();
    }
  }

  Future<void> dispose() async {
    await _dataSub?.cancel();
    await _connSub?.cancel();
  }
}

// ===== binding ตัวกลางให้ session ใช้งานง่าย =====
class _ParserBinding {
  _ParserBinding._(this._mapStream, this._bpStream, this._tempStream);

  final Stream<Map<String, String>>? _mapStream;
  final Stream<BpReading>? _bpStream;
  final Stream<double>? _tempStream;

  static _ParserBinding map(Stream<Map<String, String>> s) =>
      _ParserBinding._(s, null, null);
  static _ParserBinding bp(Stream<BpReading> s) =>
      _ParserBinding._(null, s, null);
  static _ParserBinding temp(Stream<double> s) =>
      _ParserBinding._(null, null, s);

  StreamSubscription listen({
    required void Function(Map<String, String> m) onMap,
    required void Function(BpReading bp) onBp,
    required void Function(double t) onTempC,
    required void Function(Object e) onError,
  }) {
    if (_mapStream != null) {
      return _mapStream!.listen(onMap, onError: onError);
    } else if (_bpStream != null) {
      return _bpStream!.listen(onBp, onError: onError);
    } else if (_tempStream != null) {
      return _tempStream!.listen(onTempC, onError: onError);
    } else {
      return const Stream<Map<String, String>>.empty().listen((_) {});
    }
  }
}