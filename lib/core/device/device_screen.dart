// lib/core/device/device_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

// หน้าจออื่น
import 'package:smarttelemed_v4/core/device/device_connect.dart';
import 'package:smarttelemed_v4/core/device/device_page.dart';

// parsers
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';        // AdUa651Ble + BpReading
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_yhw_6.dart';     // YuwellYhw6 (Stream<double>)
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_glucose.dart';   // YuwellGlucose (Stream<Map>)
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart'; // YuwellFpoYx110 (Stream<Map>)
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_po_jpd_500f.dart'; // JumperPoJpd500f (Stream<Map>)
import 'package:smarttelemed_v4/core/device/add_device/Mi/mibfs_05hm.dart'; // Mibfs05Hm (Stream<Map>)

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // จัดการเซสชัน (หนึ่งเครื่อง = หนึ่งเซสชัน)
  final Map<String, _DeviceSession> _sessions = {};

  // สำหรับ refresh ปุ่มมุมขวาบน/หลังกลับจากหน้าเชื่อมต่อ
  bool _loading = false;

  // GUID ที่ใช้ตรวจจับบริการที่รองรับ
  // BP
  static final Guid svcBp      = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid chrBpMeas  = Guid('00002a35-0000-1000-8000-00805f9b34fb');
  // Thermometer
  static final Guid svcThermo  = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid chrTemp    = Guid('00002a1c-0000-1000-8000-00805f9b34fb');
  // Glucose
  static final Guid svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb');
  // Yuwell-like Oximeter
  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');
  // Body Composition (สำหรับ MIBFS)
  static final Guid svcBody   = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid chrBodyMx = Guid('00002a9c-0000-1000-8000-00805f9b34fb');
  // Jumper (ล็อกใช้เฉพาะ characteristic)
  static final Guid chrCde81   = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');

  @override
  void initState() {
    super.initState();
    _refreshConnected();
  }

  @override
  void dispose() {
    for (final s in _sessions.values) {
      s.dispose();
    }
    super.dispose();
  }

  // ====== ค้นหาอุปกรณ์ที่เชื่อมต่ออยู่และเริ่มเซสชัน ======
  Future<void> _refreshConnected() async {
    setState(() => _loading = true);
    try {
      // ดึงรายการอุปกรณ์ที่เชื่อมต่ออยู่ตอนนี้
      final List<BluetoothDevice> devs = await FlutterBluePlus.connectedDevices;
      // เพิ่มเซสชันใหม่สำหรับอุปกรณ์ที่ยังไม่มี
      for (final d in devs) {
        if (!_sessions.containsKey(d.remoteId.str)) {
          await _createAndStartSession(d);
        }
      }
      // ลบเซสชันที่อุปกรณ์ไม่ได้เชื่อมต่อแล้ว
      final idsAlive = devs.map((e) => e.remoteId.str).toSet();
      final toRemove = _sessions.keys.where((k) => !idsAlive.contains(k)).toList();
      for (final id in toRemove) {
        _sessions[id]?.dispose();
        _sessions.remove(id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดอุปกรณ์ที่เชื่อมต่ออยู่ไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createAndStartSession(BluetoothDevice d) async {
    final session = _DeviceSession(
      device: d,
      onUpdate: () => setState(() {}),
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${d.platformName.isNotEmpty ? d.platformName : d.remoteId.str}: $err')),
        );
      },
    );
    _sessions[d.remoteId.str] = session;
    await session.start(
      pickParser: (device, services) => _pickParser(device, services),
    );
  }

  // เลือก parser ตามบริการ/คาแรกเตอร์ริสติค (ล็อก Jumper เฉพาะ chrCde81)
  Future<_ParserBinding> _pickParser(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    bool hasSvc(Guid svc) => services.any((s) => s.uuid == svc);
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

    // 1) Jumper: ใช้ "เฉพาะ" chrCde81 เท่านั้น
    if (hasAnyChr(chrCde81)) {
      final stream = await JumperPoJpd500f(device: device).parse(); // Stream<Map<String,String>>
      return _ParserBinding.map(stream);
    }

    // 2) BP
    if (hasSvc(svcBp) && hasChr(svcBp, chrBpMeas)) {
      final s = await AdUa651Ble(device: device).parse(); // Stream<BpReading>
      return _ParserBinding.bp(s);
    }

    // 3) Thermometer
    if (hasSvc(svcThermo) && hasChr(svcThermo, chrTemp)) {
      final s = await YuwellYhw6(device: device).parse(); // Stream<double>
      return _ParserBinding.temp(s);
    }

    // 4) Glucose
    if (hasSvc(svcGlucose) && hasChr(svcGlucose, chrGluMeas)) {
      final s = await YuwellGlucose(device: device).parse(); // Stream<Map>
      return _ParserBinding.map(s);
    }

    // 5) Yuwell Oximeter (FFE0/FFE4)
    if (hasSvc(svcFfe0) && hasChr(svcFfe0, chrFfe4)) {
      final s = await YuwellFpoYx110(device: device).parse(); // Stream<Map>
      return _ParserBinding.map(s);
    }
    if (hasSvc(svcBody) && hasChr(svcBody, chrBodyMx)) {
    final s = await MiBfs05hm(device: device).parse();
     return _ParserBinding.map(s);
  }

    // ไม่รองรับ → คืน empty
    throw Exception('ยังไม่รองรับอุปกรณ์นี้ (ไม่พบ Service/Characteristic ที่รู้จัก)');
  }

  // ====== UI ======
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
          // ไปหน้าเชื่อมต่ออุปกรณ์ แล้วกลับมารีเฟรช + สร้างเซสชันใหม่อัตโนมัติ
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
                        MaterialPageRoute(
                          builder: (_) => DevicePage(device: sessions[i].device),
                        ),
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

// ====== การ์ดแสดงผลต่ออุปกรณ์ ======
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
              OutlinedButton(
                onPressed: onOpen,
                child: const Text('เปิด'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onDisconnect,
                child: const Text('ตัดการเชื่อมต่อ'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('ID: $id', style: const TextStyle(color: Colors.black54)),
          const Divider(),

          if (error != null) ...[
            Text('ผิดพลาด: $error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
          ],

          if (spo2 != null || pr != null) ...[
            Text('SpO₂: ${spo2?.toString() ?? '-'} %',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Pulse: ${pr?.toString() ?? '-'} bpm',
                style: const TextStyle(fontSize: 18)),
            const Divider(),
          ],

          if (data.isEmpty)
            const Text('ยังไม่มีข้อมูลจากอุปกรณ์')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries
                  .where((e) => !{
                        'spo2','SpO2','SPO2',
                        'pr','PR','pulse',
                      }.contains(e.key))
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
            ),
        ]),
      ),
    );
  }
}

// ====== เซสชันต่ออุปกรณ์ (เลือก parser + ฟังสตรีม + อัปเดตค่า) ======
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
    // เฝ้าสถานะ เพื่อเคลียร์เมื่อหลุด
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        latestData = {};
        onUpdate();
      }
    });

    try {
      // กันชน: หยุดสแกนก่อน
      try { await FlutterBluePlus.stopScan(); } catch (_) {}

      // ต่อให้อยู่ในสถานะไหน ขอให้มั่นใจว่า connected
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

      // discover
      final services = await device.discoverServices();

      // เลือก parser
      final binding = await pickParser(device, services);

      // subscribe
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

// ====== ตัวกลางผูกสตรีมจาก parser ให้ใช้ง่ายกับ session ======
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
      // ไม่ควรเกิด
      return const Stream<Map<String, String>>.empty().listen((_) {});
    }
  }
}
