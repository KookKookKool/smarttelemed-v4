// device_connect.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_page.dart';

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({Key? key}) : super(key: key);

  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  bool _appBtEnabled = true; // Soft On/Off ภายในแอป
  bool _isScanning = false;

  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  String? _rememberedDeviceId;
  String? _rememberedDeviceName;

  int? _lastRssi;
  bool _autoTriedReconnect = false;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.adapterState.listen((s) {
      setState(() => _adapterState = s);
      if (s == BluetoothAdapterState.on && !_autoTriedReconnect) {
        _autoTriedReconnect = true;
        _autoReconnectIfRemembered();
      }
    });

    _init();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadRememberedDevice();
    await _requestPermissionsIfNeeded();
    _adapterState = await FlutterBluePlus.adapterState.first;
    if (_adapterState == BluetoothAdapterState.on) {
      _autoReconnectIfRemembered();
    }
    setState((){});
  }

  Future<void> _requestPermissionsIfNeeded() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      final loc = await Permission.locationWhenInUse.request(); // สำหรับ Android <12
      if (!scan.isGranted || !connect.isGranted || !loc.isGranted) {
        _snack('กรุณาอนุญาตสิทธิ์ Bluetooth/Location ให้ครบ');
      }
    } else if (Platform.isIOS) {
      await Permission.locationWhenInUse.request(); // เผื่อสแกนต้องใช้
    }
  }

  // ---------- Soft Off / On ----------
  Future<void> _softBluetoothOff() async {
    _appBtEnabled = false;
    await _stopScan();
    await _disconnect();
    if (mounted) setState((){});
  }

  Future<void> _softBluetoothOn() async {
    _appBtEnabled = true;
    if (mounted) setState((){});
  }

  // ---------- Scan ----------
  Future<void> _startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_adapterState != BluetoothAdapterState.on) {
      _snack('กรุณาเปิด Bluetooth ของเครื่องก่อน');
      return;
    }
    if (!_appBtEnabled) {
      _snack('Bluetooth ถูกปิดในแอป (Soft Off)');
      return;
    }
    if (_isScanning) return;

    setState(() => _isScanning = true);
    await _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      // auto-connect ถ้าพบอุปกรณ์ที่จำไว้
      if (_rememberedDeviceId != null && _connectedDevice == null) {
        final hit = results.where((r) => r.device.remoteId.str == _rememberedDeviceId).toList();
        if (hit.isNotEmpty) {
          await _connectToDevice(hit.first.device);
          await _stopScan();
        }
      }
      // UI ของผลสแกนใช้ StreamBuilder ในลิสต์ด้านล่าง
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      _snack('สแกนไม่สำเร็จ: $e');
      await _stopScan();
    }
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();
    if (mounted) setState(() => _isScanning = false);
  }

  // ---------- Connect / Disconnect ----------
  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (!_appBtEnabled) {
      _snack('Bluetooth ถูกปิดในแอป (Soft Off)');
      return;
    }
    try {
      _snack('กำลังเชื่อมต่อ ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}');
      await device.connect(timeout: const Duration(seconds: 10));
      setState(() => _connectedDevice = device);

      await _connSub?.cancel();
      _connSub = device.connectionState.listen((s) async {
        if (!mounted) return;
        if (s == BluetoothConnectionState.connected) {
          setState(() => _connectedDevice = device);
          await _rememberDevice(device);
          try { await device.requestMtu(247); } catch (_) {}
          _readRssi();

          // นำทางไปหน้าอ่านค่า
          if (mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DevicePage(device: device),
            ));
          }
        } else if (s == BluetoothConnectionState.disconnected) {
          setState(() {
            _connectedDevice = null;
            _lastRssi = null;
          });
        }
      });

      await device.discoverServices();
    } catch (e) {
      _snack('เชื่อมต่อไม่สำเร็จ: $e');
    }
  }

  Future<void> _disconnect() async {
    final d = _connectedDevice;
    if (d == null) return;
    try {
      await d.disconnect();
      setState(() {
        _connectedDevice = null;
        _lastRssi = null;
      });
    } catch (e) {
      _snack('ตัดการเชื่อมต่อไม่สำเร็จ: $e');
    }
  }

  Future<void> _readRssi() async {
    final d = _connectedDevice;
    if (d == null) return;
    try {
      final rssi = await d.readRssi();
      if (mounted) setState(() => _lastRssi = rssi);
    } catch (_) {}
  }

  // ---------- Remember ----------
  Future<void> _rememberDevice(BluetoothDevice d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_device_id', d.remoteId.str);
    await prefs.setString('last_device_name', d.platformName);
    setState(() {
      _rememberedDeviceId = d.remoteId.str;
      _rememberedDeviceName = d.platformName;
    });
  }

  Future<void> _loadRememberedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberedDeviceId = prefs.getString('last_device_id');
      _rememberedDeviceName = prefs.getString('last_device_name');
    });
  }

  Future<void> _autoReconnectIfRemembered() async {
    if (_rememberedDeviceId == null) {
      _startScan();
      return;
    }
    try {
      final d = BluetoothDevice.fromId(_rememberedDeviceId!);
      await _connectToDevice(d);
    } catch (_) {
      await _startScan();
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isHwOn = _adapterState == BluetoothAdapterState.on;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Connect')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Soft On/Off ภายในแอป
            Row(
              children: [
                const Text('ใช้ Bluetooth ในแอป', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Switch(
                  value: _appBtEnabled,
                  onChanged: (v) async => v ? _softBluetoothOn() : _softBluetoothOff(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('สถานะเครื่อง: ${_adapterStateLabel(_adapterState)}'),
            ),
            if (Platform.isAndroid && !isHwOn)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('เปิด Bluetooth ของเครื่อง'),
                  onPressed: () async {
                    try { await FlutterBluePlus.turnOn(); } catch (e) { _snack('เปิด Bluetooth ไม่ได้: $e'); }
                  },
                ),
              ),

            const SizedBox(height: 12),

            // อุปกรณ์ล่าสุด
            if (_rememberedDeviceId != null && _connectedDevice == null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('อุปกรณ์ที่เคยเชื่อมต่อล่าสุด', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              _rememberedCard(),
              const SizedBox(height: 8),
            ],

            // ปุ่มสแกน
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (isHwOn && _appBtEnabled && !_isScanning) ? () => _startScan() : null,
                  icon: const Icon(Icons.search),
                  label: Text(_isScanning ? 'กำลังค้นหา...' : 'ค้นหาอุปกรณ์'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isScanning ? _stopScan : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('หยุดค้นหา'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // รายการผลสแกน (เลื่อนดู)
            SizedBox(height: 320, child: _buildScanList()),
          ],
        ),
      ),
    );
  }

  Widget _buildScanList() {
    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBluePlus.scanResults,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(_isScanning ? 'กำลังค้นหาอุปกรณ์...' : 'ยังไม่พบอุปกรณ์ใกล้เคียง'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = items[i];
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : (r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : 'Unknown');
            final id = r.device.remoteId.str;
            final rssi = r.rssi;
            return ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(name),
              subtitle: Text('$id · RSSI $rssi'),
              trailing: ElevatedButton(
                onPressed: () async => _connectToDevice(r.device),
                child: const Text('เชื่อมต่อ'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _rememberedCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(_rememberedDeviceName?.isNotEmpty == true ? _rememberedDeviceName! : _rememberedDeviceId!),
        subtitle: const Text('อุปกรณ์ที่เคยเชื่อมต่อ'),
        trailing: ElevatedButton(
          child: const Text('เชื่อมต่ออีกครั้ง'),
          onPressed: () async {
            try {
              final d = BluetoothDevice.fromId(_rememberedDeviceId!);
              await _connectToDevice(d);
            } catch (_) {
              _snack('กำลังค้นหาอุปกรณ์...'); 
              await _startScan();
            }
          },
        ),
      ),
    );
  }

  String _adapterStateLabel(BluetoothAdapterState s) {
    switch (s) {
      case BluetoothAdapterState.on: return 'เปิดใช้งาน';
      case BluetoothAdapterState.off: return 'ปิดอยู่';
      case BluetoothAdapterState.turningOn: return 'กำลังเปิด';
      case BluetoothAdapterState.turningOff: return 'กำลังปิด';
      case BluetoothAdapterState.unauthorized: return 'ยังไม่ได้อนุญาตสิทธิ์';
      case BluetoothAdapterState.unavailable: return 'อุปกรณ์ไม่รองรับ';
      default: return 'ไม่ทราบสถานะ';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
