// DeviceConnectPage (เฉพาะส่วนสำคัญ)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_page.dart';

class DeviceConnectPage extends StatefulWidget {
  const DeviceConnectPage({super.key});
  @override
  State<DeviceConnectPage> createState() => _DeviceConnectPageState();
}

class _DeviceConnectPageState extends State<DeviceConnectPage> {
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  @override
  void initState() {
    super.initState();
    _subscribeStreams();
    _ensurePermissions().then((_) => _startScan());
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _ensurePermissions() async {
    // สำหรับ Android 12+ ต้องมีสองสิทธิ์นี้
    if (Theme.of(context).platform == TargetPlatform.android) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      // รุ่นเก่า <12 ยังต้อง location
      await Permission.locationWhenInUse.request();
    }
  }

  void _subscribeStreams() {
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _scanResults
          ..clear()
          ..addAll(results);
      });
    });
    _isScanningSub = FlutterBluePlus.isScanning.listen((s) {
      if (!mounted) return;
      setState(() => _isScanning = s);
    });
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() => _scanResults.clear());
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (e) {
      _snack('เริ่มสแกนไม่สำเร็จ: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();

      // หลีกเลี่ยง connect ซ้อน
      final state = await device.connectionState.first;
      if (state == BluetoothConnectionState.disconnected) {
        await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
        // รอจนเป็น connected หรือหลุด
        await device.connectionState
            .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
            .first
            .timeout(const Duration(seconds: 12));
      }

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DevicePage(device: device)));
    } catch (e) {
      _snack('เชื่อมต่อไม่สำเร็จ: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _friendlyName(ScanResult r) {
    if (r.device.platformName.isNotEmpty) return r.device.platformName;
    if (r.advertisementData.advName.isNotEmpty) return r.advertisementData.advName;
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ค้นหาอุปกรณ์')),
      body: Column(
        children: [
          if (_isScanning) const LinearProgressIndicator(),
          Expanded(
            child: _scanResults.isEmpty
                ? const Center(child: Text('ยังไม่พบอุปกรณ์ใกล้เคียง'))
                : ListView.separated(
                    itemCount: _scanResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _scanResults[i];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(_friendlyName(r)),
                        subtitle: Text('${r.device.remoteId.str} · RSSI ${r.rssi}'),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(r.device),
                          child: const Text('เชื่อมต่อ'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? FlutterBluePlus.stopScan : _startScan,
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
