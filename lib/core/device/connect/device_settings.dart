// lib/core/device/device_setting.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSettingPage extends StatefulWidget {
  const DeviceSettingPage({super.key});

  @override
  State<DeviceSettingPage> createState() => _DeviceSettingPageState();
}

class _DeviceSettingPageState extends State<DeviceSettingPage> {
  // ---------- Scan ----------
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _scanFlagSub;
  bool _isScanning = false;

  // ---------- Discovered ----------
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, String> _names = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connSubs = {};
  final Set<String> _connected = {};

  // ---------- Persisted Installed ----------
  Set<String> _installedIds = {};

  // ---------- Misc ----------
  Timer? _autoPrune;
  static const Duration _retain = Duration(seconds: 12);

  // Manual add
  final TextEditingController _manualCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstalledIds();
    _requestPerms().then((_) => _startScan());
    _autoPrune = Timer.periodic(const Duration(seconds: 6), (_) => _pruneOffline());
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _scanFlagSub?.cancel();
    _autoPrune?.cancel();
    for (final s in _connSubs.values) {
      s.cancel();
    }
    _manualCtl.dispose();
    super.dispose();
  }

  // ---------- Permissions ----------
  Future<void> _requestPerms() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();
    }
  }

  // ---------- Persist helpers (installed_device_ids) ----------
  Future<void> _loadInstalledIds() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _installedIds = (p.getStringList('installed_device_ids') ?? const <String>[])
          .where((e) => e.trim().isNotEmpty)
          .toSet();
    });
  }

  Future<void> _saveInstalledIds() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('installed_device_ids', _installedIds.toList());
  }

  Future<void> _addInstalled(String id) async {
    if (_installedIds.add(id)) {
      await _saveInstalledIds();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เพิ่มอุปกรณ์ไว้ถาวรแล้ว: $id')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('มีอุปกรณ์นี้อยู่แล้ว')));
      }
    }
  }

  Future<void> _removeInstalled(String id) async {
    if (_installedIds.remove(id)) {
      await _saveInstalledIds();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ลบอุปกรณ์ออกจากรายการถาวร: $id')));
      }
    }
  }

  // ---------- Scan ----------
  void _startScan() async {
    await _scanSub?.cancel();
    await _scanFlagSub?.cancel();

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

        _watchDevice(r.device);
      }
      _pruneOffline();
      if (mounted) setState(() {});
    });

    _scanFlagSub = FlutterBluePlus.isScanning.listen((s) {
      if (mounted) setState(() => _isScanning = s);
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สแกนไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  void _pruneOffline() {
    final now = DateTime.now();
    final remove = <String>[];
    for (final id in _devices.keys) {
      final seen = _lastSeen[id];
      final connected = _connected.contains(id);
      final online = connected || (seen != null && now.difference(seen) <= _retain);
      if (!online) {
        remove.add(id);
      }
    }
    for (final id in remove) {
      _devices.remove(id);
      _names.remove(id);
      _lastSeen.remove(id);
    }
  }

  void _watchDevice(BluetoothDevice d) {
    final id = d.remoteId.str;
    if (_connSubs.containsKey(id)) return;
    _connSubs[id] = d.connectionState.listen((s) {
      if (!mounted) return;
      setState(() {
        if (s == BluetoothConnectionState.connected) {
          _connected.add(id);
        } else {
          _connected.remove(id);
        }
      });
    });
  }

  // ---------- UI helpers ----------
  List<String> get _visibleDiscovered {
    final now = DateTime.now();
    final ids = _devices.keys.where((id) {
      final seen = _lastSeen[id];
      final connected = _connected.contains(id);
      final online = connected || (seen != null && now.difference(seen) <= _retain);
      return online;
    }).toList();

    ids.sort((a, b) {
      final ca = _connected.contains(a) ? 0 : 1;
      final cb = _connected.contains(b) ? 0 : 1;
      if (ca != cb) return ca - cb;

      final ta = _lastSeen[a]?.millisecondsSinceEpoch ?? 0;
      final tb = _lastSeen[b]?.millisecondsSinceEpoch ?? 0;
      if (ta != tb) return tb.compareTo(ta);

      return (_names[a] ?? a).compareTo(_names[b] ?? b);
    });
    return ids;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final discovered = _visibleDiscovered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าอุปกรณ์ (Bluetooth)'),
        actions: [
          IconButton(
            tooltip: _isScanning ? 'หยุดสแกน' : 'สแกน',
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _isScanning ? _stopScan : _startScan,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // -------- Installed devices (persisted) --------
          const Text('อุปกรณ์ที่บันทึกไว้ถาวร',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_installedIds.isEmpty)
            _cardPadding(const Text('ยังไม่มีอุปกรณ์ที่บันทึกไว้'))
          else
            ...(_installedIds.toList()..sort()).map((id) {
              final name = _names[id] ?? 'Unknown';
              final connected = _connected.contains(id);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.memory),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(id, style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stateChip(
                        connected ? 'Connected' : 'Saved',
                        connected ? Colors.green : Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'ลบออก',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeInstalled(id),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // -------- Discover & add --------
          Row(
            children: [
              const Text('อุปกรณ์ที่พบ ณ ตอนนี้',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: discovered.isEmpty
                    ? null
                    : () async {
                        for (final id in discovered) {
                          await _addInstalled(id);
                        }
                      },
                icon: const Icon(Icons.library_add),
                label: const Text('เพิ่มทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (discovered.isEmpty)
            _cardPadding(const Text('ยังไม่พบอุปกรณ์ใกล้เคียง — กดปุ่มสแกนที่มุมขวาบน'))
          else
            ...discovered.map((id) {
              final name = _names[id] ?? 'Unknown';
              final connected = _connected.contains(id);
              final installed = _installedIds.contains(id);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.bluetooth_searching),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(id, style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stateChip(
                        connected ? 'Connected' : 'Online',
                        connected ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(installed ? Icons.check : Icons.add),
                        label: Text(installed ? 'บันทึกแล้ว' : 'เพิ่มถาวร'),
                        onPressed: installed ? null : () => _addInstalled(id),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // -------- Manual add --------
          const Text('เพิ่มด้วยตนเอง (พิมพ์ Remote ID)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _manualCtl,
                    decoration: const InputDecoration(
                      labelText: 'เช่น AA:BB:CC:DD:EE:FF หรือ <platform-remote-id>',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _onManualAdd(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _onManualAdd,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกถาวร'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateChip(String text, Color color) {
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _cardPadding(Widget child) => Card(
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      );

  Future<void> _onManualAdd() async {
    final id = _manualCtl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Remote ID')),
      );
      return;
    }
    await _addInstalled(id);
    _manualCtl.clear();
  }
}
