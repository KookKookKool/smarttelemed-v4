// lib/core/device/device_connect.dart
import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smarttelemed_v4/core/device/device_page.dart';
import 'package:smarttelemed_v4/core/device/device_screen.dart';

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key});
  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  // ---------------- Scan streams ----------------
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  bool _isScanning = false;

  // ---------------- Known devices (คงอยู่แม้หยุดสแกน) ----------------
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, String> _names = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, bool> _supportedMap = {};

  // เก็บการ subscribe สถานะการเชื่อมต่อ
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connSubs = {};
  final Set<String> _connectingIds = {};
  final Set<String> _connectedIds  = {};

  // ---------------- Filters ----------------
  Set<String> _installedIds = {};
  bool _installedOnly = false; // แสดงทั้งหมด (auto-connect เฉพาะที่บันทึกไว้)
  // จะล็อก UI ให้เปิดค่านี้เสมอ
  bool _supportedOnly = true; // จะล็อก UI ให้ปิดค่านี้เสมอ

  // ---------------- Auto-connect ----------------
  final Queue<String> _autoQueue = Queue<String>();
  bool _autoConnecting = false;
  Timer? _rescanTimer; // สแกนซ้ำเป็นระยะ

  // คีย์/เทลสำหรับช่วยจำแนก (ใช้แค่ UI/ฟิลเตอร์แสดงผล)
  static const Set<String> _supportedServiceTails = {
    'cb80', // Jumper service (บางรุ่น)
    '1822', // PLX (oximeter)
    '1810', // Blood Pressure
    '1809', // Thermometer (มาตรฐาน)
    '1808', // Glucose
    '181b', // Body Composition (MIBFS)
    'ffe0', // Yuwell-like oximeter
    'ffb0', // Jumper BFS-710 family
    'fee0', // Jumper BFS-710 family
    'fff0', // ← Jumper FR400 thermometer (vendor)
  };

  static const List<String> _nameKeywords = [
    // Oximeter/BP etc.
    'oximeter','my oximeter','jumper','jpd',
    'yuwell','ua-651','ua651','ye680a',
    'glucose','mibfs','scale','bfs','swan',
    // Thermometer/FR400
    'thermometer','my thermometer','temperature',
    'fr400','fr-400','jpd-fr400','jpd fr400',
    'ft95', // เผื่อเทอร์โมมิเตอร์ Beurer
  ];

  // เก็บแค่ 2 นาทีถ้าไม่ได้เชื่อมต่อ (ลิสต์จะไม่ว่างเปล่าทันที)
  static const Duration _retainDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();

    // ล็อกโหมดให้แสดง/ต่อเฉพาะอุปกรณ์ที่บันทึกไว้
    _supportedOnly = true;

    _loadInstalledIds();
    _requestPerms().then((_) => _startScan());

    // re-scan อัตโนมัติทุก 8 วินาที (ถ้าไม่ได้สแกนอยู่)
    _rescanTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_isScanning) _startScan();
    });
  }

  @override
  void dispose() {
    _rescanTimer?.cancel();
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    for (final s in _connSubs.values) { s.cancel(); }
    super.dispose();
  }

  // ------------ Permissions ------------
  Future<void> _requestPerms() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();
    }
  }

  // ------------ Installed list ------------
  Future<void> _loadInstalledIds() async {
    final prefs = await SharedPreferences.getInstance();
    _installedIds = (prefs.getStringList('installed_device_ids') ?? []).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _saveInstalledIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('installed_device_ids', _installedIds.toList());
  }

  void _toggleInstalled(String id) async {
    if (_installedIds.contains(id)) {
      _installedIds.remove(id);
    } else {
      _installedIds.add(id);
    }
    await _saveInstalledIds();
    if (mounted) setState(() {});
  }

  // ------------ Auto-connect helpers ------------
  void _maybeAutoConnect(ScanResult r) {
    final id = r.device.remoteId.str;
    if (!_installedIds.contains(id)) return; // <- ไม่บันทึก = ไม่ auto
    if (_connectingIds.contains(id) || _connectedIds.contains(id) || _autoQueue.contains(id)) return;
    _autoQueue.add(id);
    _drainAutoQueue();
  }

  Future<void> _drainAutoQueue() async {
    if (_autoConnecting) return;
    _autoConnecting = true;
    try {
      while (_autoQueue.isNotEmpty && mounted) {
        final id = _autoQueue.removeFirst();
        final dev = _devices[id];
        if (dev != null && !_connectedIds.contains(id)) {
          try {
            await _connectTo(dev); // มี stopScan/resume ภายในแล้ว
          } catch (_) {
            // เงียบไว้เพื่อให้คิวไปต่อ (Snackbar อยู่ใน _connectTo แล้ว)
          }
          // เว้นจังหวะกันชน GATT
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }
    } finally {
      _autoConnecting = false;
    }
  }

  // ------------ Scan ------------
  void _startScan() async {
    if (_isScanning) return;

    await _scanSub?.cancel();
    await _isScanningSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final now = DateTime.now();
      for (final r in results) {
        final id = r.device.remoteId.str;
        _devices[id] = r.device;
        _names[id] = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : 'Unknown');
        _lastSeen[id] = now;
        _supportedMap[id] = _matchSupported(r);
        _watchDevice(r.device);

        // 🔁 ต่ออัตโนมัติถ้าเป็นอุปกรณ์ที่บันทึกไว้
        _maybeAutoConnect(r);
      }
      if (mounted) setState(() {});
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((s) {
      if (mounted) setState(() => _isScanning = s);
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เริ่มสแกนไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _stopScan() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
  }

  // ------------ Connection watchers ------------
  void _watchDevice(BluetoothDevice d) {
    final id = d.remoteId.str;
    if (_connSubs.containsKey(id)) return;

    _connSubs[id] = d.connectionState.listen((s) {
      if (!mounted) return;
      setState(() {
        if (s == BluetoothConnectionState.connected) {
          _connectedIds.add(id);
        } else {
          _connectedIds.remove(id);
        }
        _connectingIds.remove(id);
      });
    });
  }

  Future<void> _connectTo(BluetoothDevice d) async {
    final id = d.remoteId.str;
    _watchDevice(d);

    // เพื่อเลี่ยงชน GATT บนอุปกรณ์บางรุ่น เราหยุดสแกน แต่ "ลิสต์จะไม่หาย"
    final wasScanning = _isScanning;
    await _stopScan();

    setState(() => _connectingIds.add(id));
    try {
      await d.connect(autoConnect: false, timeout: const Duration(seconds: 12));
      _installedIds.add(id);        // บันทึกเข้ารายการของฉันเสมอเมื่อเชื่อมต่อสำเร็จ
      await _saveInstalledIds();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เชื่อมต่อกับ ${_names[id] ?? id} สำเร็จ'),
          action: SnackBarAction(
            label: 'เปิดแดชบอร์ด',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _connectingIds.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เชื่อมต่อไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (wasScanning) _startScan();
    }
  }

  Future<void> _disconnectFrom(BluetoothDevice d) async {
    final id = d.remoteId.str;
    try { await d.disconnect(); } catch (_) {}
    if (mounted) {
      setState(() {
        _connectedIds.remove(id);
        _connectingIds.remove(id);
      });
    }
  }

  // ------------ Filters ------------
  bool _guidsHaveTail(Iterable<Guid> guids, String tail4) {
    final t = tail4.toLowerCase();
    for (final g in guids) {
      final s = g.str.toLowerCase();
      final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
      if (tail == t) return true;
    }
    return false;
  }

  bool _advHasSvcTail(ScanResult r, String tail4) =>
      _guidsHaveTail(r.advertisementData.serviceUuids, tail4);

  bool _advHasSvcDataTail(ScanResult r, String tail4) =>
      _guidsHaveTail(r.advertisementData.serviceData.keys, tail4);

  bool _matchSupported(ScanResult r) {
    // ชื่ออุปกรณ์
    final name = (r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName)
        .toLowerCase();
    if (name.isNotEmpty) {
      for (final k in _nameKeywords) {
        if (name.contains(k)) return true;
      }
    }

    // Service UUIDs (โฆษณา)
    for (final g in r.advertisementData.serviceUuids) {
      final s = g.str.toLowerCase();
      final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
      if (_supportedServiceTails.contains(tail)) return true;
    }

    // เคสพิเศษ: Xiaomi/Mi Scale (MIBFS)
    final isXiaomi = r.advertisementData.manufacturerData.keys.contains(0x0157);
    final looksLikeScale = name.contains('mibfs') || name.contains('scale');
    final hasBodyComp = _advHasSvcTail(r, '181b') || _advHasSvcDataTail(r, '181b');
    final hasMiBeacon = _advHasSvcDataTail(r, 'fe95');
    if (isXiaomi && (hasBodyComp || hasMiBeacon || looksLikeScale)) return true;

    // เคสพิเศษ: Jumper thermometer (FR400) — Manufacturer ID ที่พบในรูป = 0xC11C
    if (r.advertisementData.manufacturerData.keys.contains(0xC11C)) return true;

    return false;
  }

  List<String> get _visibleIds {
    final now = DateTime.now();
    final all = <String>{
      ..._devices.keys,
      ..._installedIds,
      ..._connectedIds,
    };

    bool keep(String id) {
      // เก็บถ้าเชื่อมต่ออยู่เสมอ
      if (_connectedIds.contains(id)) return true;

      // ถ้าเคยเห็นไม่เกิน retainDuration
      final seen = _lastSeen[id];
      if (seen != null && now.difference(seen) <= _retainDuration) {
        // ผ่านเงื่อนไขการกรอง
        if (_installedOnly && !_installedIds.contains(id)) return false;
        if (_supportedOnly) {
          final supported = _supportedMap[id] ?? false;
          if (!supported && !_installedIds.contains(id)) return false;
        }
        return true;
      }

      // ถ้าเป็น “อุปกรณ์ของฉัน” ก็แสดง (แม้ยังไม่เห็นล่าสุด)
      if (_installedOnly && _installedIds.contains(id)) return true;

      return false;
    }

    final list = all.where(keep).toList();

    // จัดเรียง: Connected ก่อน, แล้วตามล่าสุด -> ชื่อ
    list.sort((a, b) {
      final ca = _connectedIds.contains(a) ? 0 : 1;
      final cb = _connectedIds.contains(b) ? 0 : 1;
      if (ca != cb) return ca - cb;

      final ta = _lastSeen[a]?.millisecondsSinceEpoch ?? 0;
      final tb = _lastSeen[b]?.millisecondsSinceEpoch ?? 0;
      if (ta != tb) return tb.compareTo(ta);

      return (_names[a] ?? a).compareTo(_names[b] ?? b);
    });

    return list;
  }

  // ------------ UI ------------
  @override
  Widget build(BuildContext context) {
    final ids = _visibleIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาอุปกรณ์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'ไปหน้าแสดงผลรวม',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startScan,
            tooltip: 'สแกนใหม่',
          ),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ล็อกโหมด: เฉพาะอุปกรณ์ที่บันทึกไว้
          SwitchListTile(
            title: const Text('แสดงเฉพาะอุปกรณ์ที่ติดตั้งแล้ว'),
            value: _installedOnly,
            onChanged: (v) => setState(() => _installedOnly = v),
          ),
          SwitchListTile(
            title: const Text('แสดงเฉพาะรุ่นที่ระบบรองรับ'),
            subtitle: const Text('คัดกรองจากชื่อ/Service UUID ในโฆษณา BLE'),
            value: _supportedOnly,
            onChanged: (v) => setState(() => _supportedOnly = v),
          ),

          const Divider(height: 1),

          Expanded(
            child: ids.isEmpty
                ? const Center(child: Text('ไม่พบอุปกรณ์ตามเงื่อนไขที่เลือก'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: ids.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final id   = ids[i];
                      final dev  = _devices[id];
                      final name = _names[id] ?? 'Offline';
                      final installed  = _installedIds.contains(id);
                      final connecting = _connectingIds.contains(id);
                      final connected  = _connectedIds.contains(id);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bluetooth),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (connected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Chip(label: Text('Connected')),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(id, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: installed
                                        ? 'ลบจากอุปกรณ์ของฉัน'
                                        : 'บันทึกเป็นอุปกรณ์ของฉัน',
                                    icon: Icon(installed
                                        ? Icons.bookmark_added
                                        : Icons.bookmark_add_outlined),
                                    onPressed: () => _toggleInstalled(id),
                                  ),
                                  if (!connected)
                                    ElevatedButton(
                                      onPressed: (connecting || dev == null)
                                          ? null
                                          : () => _connectTo(dev),
                                      child: connecting
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('เชื่อมต่อ'),
                                    )
                                  else ...[
                                    OutlinedButton(
                                      onPressed: dev == null ? null : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => DevicePage(device: dev)),
                                        );
                                      },
                                      child: const Text('เปิด (หน้าอุปกรณ์)'),
                                    ),
                                    ElevatedButton(
                                      onPressed: dev == null ? null : () => _disconnectFrom(dev),
                                      child: const Text('ตัดการเชื่อมต่อ'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        icon: Icon(_isScanning ? Icons.stop : Icons.search),
        label: Text(_isScanning ? 'หยุด' : 'สแกน'),
      ),
    );
  }
}
