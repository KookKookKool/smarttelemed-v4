// lib/core/device/device_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

// parsers
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';        // Stream<BpReading>
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_bp_ye680a.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_yhw_6.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_glucose.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_po_jpd_500f.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_ha120.dart';
import 'package:smarttelemed_v4/core/device/add_device/Mi/mibfs_05hm.dart';
import 'package:smarttelemed_v4/core/device/add_device/Beurer/beurer_tem_ft95.dart';


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
  static final Guid chrGluRacp = Guid('00002a52-0000-1000-8000-00805f9b34fb');
  // PLX (Oximeter standard)
  static final Guid svcPlx     = Guid('00001822-0000-1000-8000-00805f9b34fb');
  static final Guid chrPlxCont = Guid('00002a5f-0000-1000-8000-00805f9b34fb');
  static final Guid chrPlxSpot = Guid('00002a5e-0000-1000-8000-00805f9b34fb');
  // 🔒 Jumper: ใช้ “เฉพาะ characteristic” CDEACB81
  static final Guid chrCde81   = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');
  // Yuwell-like
  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');

  // Body Composition (มาตรฐาน) + Xiaomi proprietary (สำหรับ MIBFS)
  static final Guid svcBody    = Guid('0000181b-0000-1000-8000-00805f9b34fb'); // Body Composition
  static final Guid chrBodyMx  = Guid('00002a9c-0000-1000-8000-00805f9b34fb'); // Body Mass

  // ✅ Xiaomi private (ครอบคลุมหลายล็อต)
  static final Guid chr1530    = Guid('00001530-0000-3512-2118-0009af100700'); // weight source (prefer)
  static final Guid chr1531    = Guid('00001531-0000-3512-2118-0009af100700'); // alt
  static final Guid chr1532    = Guid('00001532-0000-3512-2118-0009af100700'); // kickoff
  static final Guid chr1542    = Guid('00001542-0000-3512-2118-0009af100700'); // alt (ดี)
  static final Guid chr1543    = Guid('00001543-0000-3512-2118-0009af100700'); // alt (มักเป็น control/ACK)
  static final Guid chr2A2Fv   = Guid('00002a2f-0000-3512-2118-0009af100700'); // vendor alt

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

      // (1) Jumper JPD-HA120 (ชื่อ/ปลาย service พบบ่อย)
      final lowerName = widget.device.platformName.toLowerCase();
      bool hasTail(String t) =>
          _services.any((s){ final u=s.uuid.str.toLowerCase(); return u.endsWith(t); });
      if (lowerName.contains('ha120') || lowerName.contains('jpd-ha120') || hasTail('af30') || hasTail('fff0')) {
        final s = await JumperJpdHa120(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // (2) Jumper PO/JPD ที่ล็อก chr CDEACB81
      if (_hasAnyChar(chrCde81)) {
        final s = await JumperPoJpd500f(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // (3) Mi Body Scale (MIBFS 05HM)
      //    ✅ รองรับทั้งมาตรฐาน BCS 0x181B และ proprietary 0x1530/1531/1532/1542/1543/2A2F
      final hasMibfs =
        _hasSvc(svcBody) || _hasChr(svcBody, chrBodyMx) ||
        _hasAnyChar(chr1530) || _hasAnyChar(chr1531) ||
        _hasAnyChar(chr1532) || _hasAnyChar(chr1542) ||
        _hasAnyChar(chr1543) || _hasAnyChar(chr2A2Fv);

      if (hasMibfs) {
        final s = await MiBfs05hm(device: widget.device).parse(); // -> Stream<Map<String,String>>
        _listenMapStream(s);
        return;
      }

      // (4) PLX มาตรฐาน (บางรุ่น Jumper)
      if (_hasSvc(svcPlx) && (_hasChr(svcPlx, chrPlxCont) || _hasChr(svcPlx, chrPlxSpot))) {
        final s = await JumperPoJpd500f(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // (5) FFE0/FFE4 → ให้พาร์เซอร์ Yuwell จัดการ
      if (_hasSvc(svcFfe0) && _hasChr(svcFfe0, chrFfe4)) {
        final s = await YuwellFpoYx110(device: widget.device).parse();
        _listenMapStream(s);
        return;
      }

      // (6) BP
      if (_hasSvc(svcBp) && _hasChr(svcBp, chrBpMeas)) {
        final s = await AdUa651Ble(device: widget.device).parse();
        _listenBpStream(s);
        return;
      }

      // (7) Thermometer
      if (_hasSvc(svcThermo) && _hasChr(svcThermo, chrTemp)) {
        final s = await YuwellYhw6(device: widget.device).parse();
        _sub?.cancel();
        _sub = s.listen(
          (tempC) => _onData({'temp': tempC.toStringAsFixed(2)}),
          onError: _onErr,
        );
        return;
      }

     // (8) Glucose (ต้องมีทั้ง 0x2A18 และ 0x2A52)
      if (_hasSvc(svcGlucose) &&
          _hasChr(svcGlucose, chrGluMeas) &&
          _hasChr(svcGlucose, chrGluRacp)) {
        final s = await YuwellGlucose(device: widget.device)
            .parse(fetchLastOnly: true, syncTime: true); // สำคัญ
        _listenMapStream(s);
        return;
      }

      // (9) Beurer FT95 Thermometer
      if (lowerName.contains('ft95') && _hasSvc(svcThermo) && _hasChr(svcThermo, chrTemp)) {
        final beurer = BeurerFt95(device: widget.device);
        await beurer.connect(); // subscribe 0x2A1C ภายในคลาส
        _sub?.cancel();
        _sub = beurer.onTemperature.listen(
          (tempC) => _onData({'temp': tempC.toStringAsFixed(2)}),
          onError: _onErr,
        );
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
                    // ✅ แสดงน้ำหนักเด่น ๆ หากเป็น MIBFS
                    if (_latestData['weight_kg'] != null) ...[
                      Text(
                        '${_latestData['weight_kg']} kg',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_latestData['bmi'] != null)
                        Text('BMI: ${_latestData['bmi']}',
                            style: const TextStyle(fontSize: 18)),
                      const Divider(),
                    ],

                    // ถ้าเป็นปลายนิ้ว (SpO2/PR) ก็แสดงแบบสวย ๆ
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
                            Text('SpO₂: ${spo2Val?.toString() ?? '-'} %',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Pulse: ${prVal?.toString() ?? '-'} bpm',
                                style: const TextStyle(fontSize: 20)),
                            const Divider(),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // แสดงคีย์อื่น ๆ ทั้งหมด (ยกเว้นที่เราจัดรูปแบบไปแล้ว)
                    ..._latestData.entries
                        .where((e) => !{
                              'weight_kg','bmi','impedance_ohm','src','raw',
                              'spo2','SpO2','SPO2',
                              'pr','PR','pulse',
                            }.contains(e.key))
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 14)),
                            )),
                    // debug fields (ถ้ามี)
                    if (_latestData['src'] != null)
                      Text('src: ${_latestData['src']}', style: const TextStyle(fontSize: 12)),
                    if (_latestData['raw'] != null)
                      Text('raw: ${_latestData['raw']}', style: const TextStyle(fontSize: 12)),
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