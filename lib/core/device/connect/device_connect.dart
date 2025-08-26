// lib/core/device/device_connect.dart
import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart'; // ⬅️ เพิ่ม
import 'package:flutter/services.dart'; // <-- เพิ่ม

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key});
  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  // ---------- Scan streams ----------
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  bool _isScanning = false;

  // ---------- Bluetooth adapter state ----------
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  // ---------- Known (installed-only, online-only) ----------
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, String> _names = {};
  final Map<String, DateTime> _lastSeen = {};

  // Connection states
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connSubs = {};
  final Set<String> _connectingIds = {};
  final Set<String> _connectedIds  = {};

  // Installed IDs (persisted)
  Set<String> _installedIds = {};

  // Seen IDs (persisted — เก็บทุกตัวที่เคยเห็น เพื่อ “ไม่หายไปไหน”)
  Set<String> _seenIds = {};

  // Auto-connect
  final Queue<String> _autoQueue = Queue<String>();
  bool _autoConnecting = false;

  // Background refresh
  Timer? _rescanTimer;
  static const Duration _scanInterval = Duration(seconds: 8);
  static const Duration _retainDuration = Duration(seconds: 10);

  // settings off bluetooth (สำหรับ native method channel ถ้าจะใช้ต่อยอด)
  static const MethodChannel _btCh = MethodChannel('app.bt');

  @override
  void initState() {
    super.initState();
    _loadSeenIds();        // โหลดรายการที่เคยเห็น
    _loadInstalledIds();   // โหลดรายการที่ติดตั้งไว้
    _requestPerms().then((_) => _startScan());

    // subscribe adapter state
    _adapterSub = FlutterBluePlus.adapterState.listen((s) {
      if (!mounted) return;
      setState(() => _adapterState = s);
    });
    // ค่าเริ่มต้น
    FlutterBluePlus.adapterState.first.then((s) {
      if (mounted) setState(() => _adapterState = s);
    });

    _rescanTimer = Timer.periodic(_scanInterval, (_) {
      if (!_isScanning) _startScan();
      _pruneOffline();
    });
  }

  @override
  void dispose() {
    _rescanTimer?.cancel();
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _adapterSub?.cancel();
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

  // ------------ Persistence helpers ------------
  Future<void> _loadInstalledIds() async {
    final prefs = await SharedPreferences.getInstance();
    _installedIds = (prefs.getStringList('installed_device_ids') ?? []).toSet();
    if (mounted) setState(() {});
  }

  Future<void> _saveInstalledIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('installed_device_ids', _installedIds.toList());
  }

  Future<void> _ensureInstalled(String id) async {
    if (_installedIds.add(id)) {
      await _saveInstalledIds();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    _seenIds = (prefs.getStringList('seen_device_ids') ?? []).toSet();
  }

  Future<void> _saveSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seen_device_ids', _seenIds.toList());
  }

  // เก็บ ID ที่ “พบ” ทุกครั้ง (ไม่กรอง) — เพื่อไม่ให้หายไปไหน
  void _rememberSeenId(String id) {
    if (_seenIds.add(id)) {
      _saveSeenIds(); // ไม่ await เพื่อไม่บล็อกสแกน
    }
  }

  Future<void> _rememberLastConnected(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_connected_device_id', id);
  }

  // ------------ Bluetooth toggle ------------
  Future<void> _onTapBluetooth() async {
    // เปิดอยู่ → ลองปิด (เฉพาะ Android มีสิทธิ์จำกัด), ถ้าทำไม่ได้ให้พาไปที่ Settings
    if (_adapterState == BluetoothAdapterState.on) {
      // ลองสั่ง native ปิด (ต้องมี implementation ฝั่ง native; ถ้าไม่มีจะตกไปเปิด Settings)
      if (Platform.isAndroid) {
        try {
          // ถ้าคุณมี native code รองรับ ให้เรียก:
          // await _btCh.invokeMethod('btOff');
          // ถ้าไม่มี native: ใช้เปิดหน้า Settings แทน
          await _openBluetoothSettings();
          return;
        } catch (_) {
          await _openBluetoothSettings();
          return;
        }
      }
      // iOS/macOS/Windows → เปิดหน้า Settings ให้ผู้ใช้ปิดเอง
      await _openBluetoothSettings();
      return;
    }

    // ปิดอยู่ → พยายามเปิด (Android เท่านั้น)
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
        return;
      } catch (e) {
        // เปิดไม่สำเร็จ → เปิด Settings แทน
      }
    }
    await _openBluetoothSettings();
  }

  Future<void> _openBluetoothSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปิดหน้า Settings ไม่สำเร็จ')),
      );
    }
  }

  // ------------ Auto-connect helpers ------------
  void _maybeAutoConnect(ScanResult r) {
    final id = r.device.remoteId.str;
    if (!_installedIds.contains(id)) return;
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
            await _connectTo(dev);
          } catch (_) {}
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

        // บันทึกทุกตัวที่เห็น (persist)
        _rememberSeenId(id);

        // เฉพาะ “ติดตั้งไว้” เท่านั้นที่จะถูกนำมาแสดง/เชื่อมต่ออัตโนมัติ
        if (!_installedIds.contains(id)) continue;

        _devices[id] = r.device;
        _names[id] = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : 'Unknown');
        _lastSeen[id] = now;

        _watchDevice(r.device);
        _maybeAutoConnect(r);
      }
      _pruneOffline();
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

  void _pruneOffline() {
    final now = DateTime.now();
    final toRemove = <String>[];
    for (final id in _devices.keys) {
      final seen = _lastSeen[id];
      final connected = _connectedIds.contains(id);
      final online = connected || (seen != null && now.difference(seen) <= _retainDuration);
      if (!online) {
        toRemove.add(id);
      }
    }
    for (final id in toRemove) {
      _devices.remove(id);
      _names.remove(id);
      _lastSeen.remove(id);
    }
  }

  void _watchDevice(BluetoothDevice d) {
    final id = d.remoteId.str;
    if (_connSubs.containsKey(id)) return;

    _connSubs[id] = d.connectionState.listen((s) async {
      if (!mounted) return;
      setState(() {
        if (s == BluetoothConnectionState.connected) {
          _connectedIds.add(id);
        } else {
          _connectedIds.remove(id);
        }
        _connectingIds.remove(id);
      });

      // เมื่อ “เชื่อมต่อสำเร็จ” → จดจำเป็น installed และเก็บ last_connected
      if (s == BluetoothConnectionState.connected) {
        await _ensureInstalled(id);         // เพิ่มเข้า installed_device_ids ถ้ายังไม่มี
        await _rememberLastConnected(id);   // เก็บ id ล่าสุดที่เชื่อมต่อ
      }
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
      // การเชื่อมต่อสำเร็จจะวิ่งเข้า listener ใน _watchDevice แล้ว
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
      _pruneOffline();
    }
  }

  // ------------ Visible list (installed ∩ online) ------------
  List<String> get _visibleIds {
    final now = DateTime.now();
    final ids = _devices.keys.where((id) {
      if (!_installedIds.contains(id)) return false;
      final seen = _lastSeen[id];
      final connected = _connectedIds.contains(id);
      final online = connected || (seen != null && now.difference(seen) <= _retainDuration);
      return online;
    }).toList();

    ids.sort((a, b) {
      final ca = _connectedIds.contains(a) ? 0 : 1;
      final cb = _connectedIds.contains(b) ? 0 : 1;
      if (ca != cb) return ca - cb;

      final ta = _lastSeen[a]?.millisecondsSinceEpoch ?? 0;
      final tb = _lastSeen[b]?.millisecondsSinceEpoch ?? 0;
      if (ta != tb) return tb.compareTo(ta);

      return (_names[a] ?? a).compareTo(_names[b] ?? b);
    });

    return ids;
  }

  bool _isOnline(String id) {
    final seen = _lastSeen[id];
    if (_connectedIds.contains(id)) return true;
    if (seen == null) return false;
    return DateTime.now().difference(seen) <= _retainDuration;
  }

  // ------------ UI ------------
  @override
  Widget build(BuildContext context) {
    final ids = _visibleIds;
    final btOn = _adapterState == BluetoothAdapterState.on;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาอุปกรณ์'),
        actions: [
          // ปุ่ม BT toggle
          IconButton(
            tooltip: btOn ? 'ปิด / ตั้งค่า Bluetooth' : 'เปิด Bluetooth',
            icon: Icon(btOn ? Icons.bluetooth : Icons.bluetooth_disabled),
            onPressed: _onTapBluetooth,
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
      body: ids.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'ยังไม่พบอุปกรณ์ที่ออนไลน์ในรายการที่บันทึกไว้',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final id   = ids[i];
                final dev  = _devices[id];
                final name = _names[id] ?? 'Unknown';
                final connecting = _connectingIds.contains(id);
                final connected  = _connectedIds.contains(id);
                final online     = _isOnline(id);

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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                connected ? 'Connected' : (online ? 'Online' : 'Offline'),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: connected
                                  ? Colors.green
                                  : (online ? Colors.orange : Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(id, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
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
                            else
                              ElevatedButton(
                                onPressed: dev == null ? null : () => _disconnectFrom(dev),
                                child: const Text('ตัดการเชื่อมต่อ'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        icon: Icon(_isScanning ? Icons.stop : Icons.search),
        label: Text(_isScanning ? 'หยุด' : 'สแกน'),
      ),
    );
  }
}
