// lib/core/device/device_connect.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ไปยังหน้าดูค่าทีละอุปกรณ์
import 'package:smarttelemed_v4/core/device/device_page.dart';
// ไปยังหน้าดูค่าทุกอุปกรณ์พร้อมกัน (แดชบอร์ด)
import 'package:smarttelemed_v4/core/device/device_screen.dart';

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key});
  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  final List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  bool _isScanning = false;

  // ---------- FILTERS ----------
  Set<String> _installedIds = {};
  bool _installedOnly = true;
  bool _supportedOnly = true;

  static const Set<String> _supportedServiceTails = {
    'cb80', '1822', '1810', '1809', '1808', 'ffe0',
  };
  static const List<String> _nameKeywords = [
    'oximeter','my oximeter','jumper','jpd','yuwell','ua-651','ua651','ye680a','glucose',
  ];

  // ---------- Multi-connect ----------
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connSubs = {};
  final Set<String> _connectingIds = {};
  final Set<String> _connectedIds  = {};

  @override
  void initState() {
    super.initState();
    _loadInstalledIds();
    _requestPerms().then((_) => _startScan());
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    for (final s in _connSubs.values) { s.cancel(); }
    super.dispose();
  }

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

  // ---------- Scan ----------
  void _startScan() async {
    if (_isScanning) return;

    _scanResults.clear();
    await _scanSub?.cancel();
    await _isScanningSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _scanResults
        ..clear()
        ..addAll(results);
      if (mounted) setState(() {});
      for (final r in results) { _watchDevice(r.device); }
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

  // ---------- Multi-connect helpers ----------
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

    final wasScanning = _isScanning;
    await _stopScan();

    setState(() => _connectingIds.add(id));
    try {
      await d.connect(autoConnect: false, timeout: const Duration(seconds: 12));
      _installedIds.add(id);
      await _saveInstalledIds();

      // ชวนไปหน้า Dashboard หลังเชื่อมต่อสำเร็จ
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เชื่อมต่อกับ ${d.platformName.isNotEmpty ? d.platformName : id} สำเร็จ'),
          action: SnackBarAction(
            label: 'เปิดหน้าแสดงผล',
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

  // ---------- Filters ----------
  bool _matchSupported(ScanResult r) {
    final name = (r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName)
        .toLowerCase();
    if (name.isNotEmpty) {
      for (final k in _nameKeywords) {
        if (name.contains(k)) return true;
      }
    }
    for (final g in r.advertisementData.serviceUuids) {
      final s = g.str.toLowerCase();
      final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
      if (_supportedServiceTails.contains(tail)) return true;
    }
    return false;
  }

  List<ScanResult> get _filteredResults {
    return _scanResults.where((r) {
      final id = r.device.remoteId.str;
      if (_installedOnly) return _installedIds.contains(id);
      if (_supportedOnly) return _matchSupported(r);
      return true;
    }).toList();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

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
          SwitchListTile(
            title: const Text('แสดงเฉพาะอุปกรณ์ที่ติดตั้งแล้ว'),
            value: _installedOnly,
            onChanged: (v) => setState(() => _installedOnly = v),
          ),
          SwitchListTile(
            title: const Text('แสดงเฉพาะรุ่นที่ระบบรองรับ'),
            subtitle: const Text('กรองจากชื่อและ Service UUID ในโฆษณา BLE'),
            value: _supportedOnly,
            onChanged: (v) => setState(() => _supportedOnly = v),
          ),
          const Divider(height: 1),

          Expanded(
            // ใช้ Card + Column + Wrap ปุ่ม เพื่อ “ไม่ล้นจอ” ทุกขนาดหน้าจอ
            child: results.isEmpty
                ? const Center(child: Text('ไม่พบอุปกรณ์ตามเงื่อนไขที่เลือก'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = results[i];
                      final dev = r.device;
                      final id  = dev.remoteId.str;
                      final name = dev.platformName.isNotEmpty
                          ? dev.platformName
                          : (r.advertisementData.advName.isNotEmpty
                              ? r.advertisementData.advName
                              : 'Unknown');
                      final installed  = _installedIds.contains(id);
                      final connecting = _connectingIds.contains(id);
                      final connected  = _connectedIds.contains(id);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // แถวหัวการ์ด
                              Row(
                                children: [
                                  const Icon(Icons.bluetooth),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              // ปุ่มแบบ Wrap (ขึ้นบรรทัดใหม่อัตโนมัติหากจอแคบ)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: installed ? 'ลบจากอุปกรณ์ของฉัน' : 'บันทึกเป็นอุปกรณ์ของฉัน',
                                    icon: Icon(installed
                                        ? Icons.bookmark_added
                                        : Icons.bookmark_add_outlined),
                                    onPressed: () => _toggleInstalled(id),
                                  ),
                                  if (!connected)
                                    ElevatedButton(
                                      onPressed: connecting ? null : () => _connectTo(dev),
                                      child: connecting
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('เชื่อมต่อ'),
                                    )
                                  else ...[
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => DevicePage(device: dev)),
                                        );
                                      },
                                      child: const Text('เปิด (หน้าอุปกรณ์)'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _disconnectFrom(dev),
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
