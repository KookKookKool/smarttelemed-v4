// lib/core/device/device_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';



// parsers
import 'package:smarttelemed_v4/core/device/add_device/ua_651ble.dart';        // Stream<BpReading>
import 'package:smarttelemed_v4/core/device/add_device/yuwell_bp_ye680a.dart'; // (ถ้ามีใช้)
import 'package:smarttelemed_v4/core/device/add_device/yuwell_fpo_yx110.dart'; // Stream<Map<String,String>>
import 'package:smarttelemed_v4/core/device/add_device/yuwell_yhw_6.dart';     // Stream<double> °C
import 'package:smarttelemed_v4/core/device/add_device/yuwell_glucose.dart';   // Stream<Map<String,String>>
import 'package:smarttelemed_v4/core/device/add_device/jumper_po_jpd_500f.dart'; // Jumper (ล็อกเฉพาะ chrCde81)

class DevicePage extends StatefulWidget {
  final BluetoothDevice device;
  const DevicePage({super.key, required this.device});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  StreamSubscription? _sub;
  Map<String, String> _latestData = {};
  String? _error;
  List<BluetoothService> _services = [];

  // Known Services/Chars
  // Blood Pressure
  static final Guid svcBp      = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid chrBpMeas  = Guid('00002a35-0000-1000-8000-00805f9b34fb');
  // Thermometer
  static final Guid svcThermo  = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid chrTemp    = Guid('00002a1c-0000-1000-8000-00805f9b34fb');
  // Glucose
  static final Guid svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb');
  // PLX (Oximeter standard)
  static final Guid svcPlx     = Guid('00001822-0000-1000-8000-00805f9b34fb');
  static final Guid chrPlxCont = Guid('00002a5f-0000-1000-8000-00805f9b34fb');
  static final Guid chrPlxSpot = Guid('00002a5e-0000-1000-8000-00805f9b34fb');
  // 🔒 Jumper: ใช้ “เฉพาะ characteristic” CDEACB81 (ไม่มี _svcCde80 อีกแล้ว)
  static final Guid chrCde81   = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');
  // Yuwell-like
  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupByService());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _setupByService() async {
    try {
      _error = null;
      setState(() {});

      // กัน connect ซ้อน + หยุดสแกน
      try { await FlutterBluePlus.stopScan(); } catch (_) {}

      var st = await widget.device.connectionState.first;
      if (st == BluetoothConnectionState.disconnected) {
        await widget.device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
        st = await widget.device.connectionState
            .where((s) => s == BluetoothConnectionState.connected || s == BluetoothConnectionState.disconnected)
            .first
            .timeout(const Duration(seconds: 12));
        if (st != BluetoothConnectionState.connected) {
          throw 'เชื่อมต่อไม่สำเร็จ (อุปกรณ์ปฏิเสธการเชื่อมต่อ)';
        }
      }

      // Discover services (retry เผื่อครั้งแรกว่าง)
      _services = [];
      for (int i = 0; i < 3; i++) {
        _services = await widget.device.discoverServices();
        if (_services.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 250));
      }

      // ---------- เลือก parser ตาม services/characteristics (เรียงความสำคัญ) ----------
      // (1) Jumper: ใช้ “เฉพาะ” characteristic CDEACB81
      if (_hasAnyChar(chrCde81)) {
        final s = await JumperPoJpd500f(device: widget.device).parse(); // ตัว parser ล็อกอ่านเฉพาะ chrCde81 แล้ว
        _listenMapStream(s);
        return;
      }

      // (2) PLX มาตรฐาน
      if (_hasSvc(svcPlx) && (_hasChr(svcPlx, chrPlxCont) || _hasChr(svcPlx, chrPlxSpot))) {
        // ❗️ถ้าอยากล็อกเฉพาะ chrCde81 จริง ๆ ให้ลบบล็อกนี้ทิ้ง
        final s = await JumperPoJpd500f(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // (3) FFE0/FFE4 → ให้พาร์เซอร์ Yuwell จัดการ
      if (_hasSvc(svcFfe0) && _hasChr(svcFfe0, chrFfe4)) {
        final s = await YuwellFpoYx110(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // (4) BP
      if (_hasSvc(svcBp) && _hasChr(svcBp, chrBpMeas)) {
        final s = await AdUa651Ble(device: widget.device).parse();
        _listenBpStream(s);
        return;
      }

      // (5) Thermometer
      if (_hasSvc(svcThermo) && _hasChr(svcThermo, chrTemp)) {
        final s = await YuwellYhw6(device: widget.device).parse();
        _sub?.cancel();
        _sub = s.listen(
          (tempC) => _onData({'temp': tempC.toStringAsFixed(2)}),
          onError: _onErr,
        );
        return;
      }

      // (6) Glucose
      if (_hasSvc(svcGlucose) && _hasChr(svcGlucose, chrGluMeas)) {
        final s = await YuwellGlucose(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // ไม่เข้าเงื่อนไขใด → แจ้งและโชว์รายการ UUID ให้ดู
      _error = 'ยังจำแนกอุปกรณ์ไม่สำเร็จ (ไม่พบ Characteristic/Service ที่รองรับ)\n'
               'ดูรายการ Service/Characteristic ด้านล่างเพื่อตรวจสอบ UUID';
      setState(() {});
    } catch (e) {
      _onErr(e);
    }

    // เฝ้า disconnect
    widget.device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อุปกรณ์ตัดการเชื่อมต่อ')),
        );
      }
    });
  }

  // ---- Helpers: ตรวจ service/char ----
  bool _hasSvc(Guid svc) => _services.any((s) => s.uuid == svc);

  bool _hasChr(Guid svc, Guid chr) {
    final s = _services.where((x) => x.uuid == svc);
    if (s.isEmpty) return false;
    return s.first.characteristics.any((c) => c.uuid == chr);
  }

  // NEW: ตรวจว่ามี characteristic ใด ๆ ที่ตรง GUID นี้ในทุก service หรือไม่
  bool _hasAnyChar(Guid chr) {
    for (final s in _services) {
      for (final c in s.characteristics) {
        if (c.uuid == chr) return true;
      }
    }
    return false;
  }

  // ---- Listeners ----
  void _listenMapStream(Stream<Map<String, String>> stream) {
    _sub?.cancel();
    _sub = stream.listen(_onData, onError: _onErr, cancelOnError: false);
  }

  void _listenBpStream(Stream<dynamic> stream) {
    _sub?.cancel();
    _sub = stream.listen((event) {
      if (event is BpReading) {
        _onData({
          'sys': event.systolic.toStringAsFixed(0),
          'dia': event.diastolic.toStringAsFixed(0),
          'map': event.map.toStringAsFixed(0),
          if (event.pulse != null) 'pul': event.pulse!.toStringAsFixed(0),
          if (event.timestamp != null) 'ts': event.timestamp!.toIso8601String(),
        });
      } else if (event is Map) {
        _onData(event.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')));
      }
    }, onError: _onErr, cancelOnError: false);
  }

  void _onData(Map<String, String> data) {
    if (!mounted) return;
    setState(() {
      _latestData = data;
      _error = null;
    });
  }

  void _onErr(Object e) {
    if (!mounted) return;
    setState(() => _error = '$e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ผิดพลาด: $e')),
    );
  }

  // ---- Value guards (กัน SPO2/PR เพี้ยน/สลับ) ----
  int? _asInt(String? s) => s == null ? null : int.tryParse(s.trim());
  int? _validSpo2(String? s) {
    final n = _asInt(s);
    if (n == null) return null;
    return (n >= 70 && n <= 100) ? n : null;
  }
  int? _validPr(String? s) {
    final n = _asInt(s);
    if (n == null) return null;
    return (n >= 30 && n <= 250) ? n : null;
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final name = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : widget.device.remoteId.str;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _setupByService,
            tooltip: 'ลองค้นหา Service ใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.link_off),
            onPressed: () async {
              try { await widget.device.disconnect(); } catch (_) {}
              if (!mounted) return;
              Navigator.pop(context);
            },
            tooltip: 'ตัดการเชื่อมต่อ',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          if (_latestData.isEmpty)
            const Text('ยังไม่มีข้อมูลจากอุปกรณ์'),
          if (_latestData.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ดึงค่าแบบปลอดภัย รองรับคีย์หลายแบบ
                    Builder(builder: (_) {
                      final spo2Val = _validSpo2(
                        _latestData['spo2'] ??
                        _latestData['SpO2'] ??
                        _latestData['SPO2'],
                      );
                      final prVal = _validPr(
                        _latestData['pr'] ??
                        _latestData['PR'] ??
                        _latestData['pulse'],
                      );

                      if (spo2Val != null || prVal != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SpO₂: ${spo2Val?.toString() ?? '-'} %',
                              style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pulse: ${prVal?.toString() ?? '-'} bpm',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Divider(),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // แสดงรายการอื่น ยกเว้นคีย์ที่ใช้แล้ว
                    ..._latestData.entries
                        .where((e) => !{
                              'spo2','SpO2','SPO2',
                              'pr','PR','pulse',
                            }.contains(e.key))
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 14)),
                            )),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Text('บริการ/คุณลักษณะ (สำหรับดีบัก)'),
          const SizedBox(height: 6),
          Expanded(
            child: _services.isEmpty
                ? const Text('ยังไม่ได้ discover services')
                : ListView(
                    children: _services
                        .map((s) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Service: ${s.uuid.str}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      ...s.characteristics.map((c) => Text(
                                            '  • Char: ${c.uuid.str}  '
                                            '${c.properties.notify ? "[notify]" : ""}'
                                            '${c.properties.indicate ? "[indicate]" : ""}',
                                          )),
                                    ]),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ]),
      ),
    );
  }
}
