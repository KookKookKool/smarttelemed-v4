// lib/core/device/device_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

// parsers
import 'package:smarttelemed_v4/shared/screens/device/add_device/A&D/ua_651ble.dart';        // Stream<BpReading>
import 'package:smarttelemed_v4/shared/screens/device/add_device/Yuwell/yuwell_bp_ye680a.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Yuwell/yuwell_fpo_yx110.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Yuwell/yuwell_yhw_6.dart';
// ใช้ตัว simple (Stream<String> mg/dL)
import 'package:smarttelemed_v4/shared/screens/device/add_device/Yuwell/yuwell_glucose.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Jumper/jumper_po_jpd_500f.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Jumper/jumper_jpd_ha120.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Mi/mibfs_05hm.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Beurer/beurer_tem_ft95.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Beurer/beurer_bm57.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Jumper/jumper_jpd_bfs710.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Jumper/jumper_jpd_fr400.dart';

class DevicePage extends StatefulWidget {
  final BluetoothDevice device;
  const DevicePage({super.key, required this.device});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  StreamSubscription<String>? _gluSub;
  StreamSubscription? _sub;
  StreamSubscription<BluetoothConnectionState>? _connMon;
  Map<String, String> _latestData = {};
  String? _error;
  List<BluetoothService> _services = [];

  JumperJpdBfs710? _bfs710;       // สำหรับ BFS-710
  BeurerBm57? _bm57;              // หากเป็น BM57 จะไม่ null
  JumperFr400? _fr400;            // FR400 thermometer

  // Known Services/Chars
  static final Guid svcBp      = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid chrBpMeas  = Guid('00002a35-0000-1000-8000-00805f9b34fb');

  static final Guid svcThermo  = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid chrTemp    = Guid('00002a1c-0000-1000-8000-00805f9b34fb');

  static final Guid svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb'); // Notify
  static final Guid chrGluRacp = Guid('00002a52-0000-1000-8000-00805f9b34fb'); // Indicate+Write

  static final Guid svcPlx     = Guid('00001822-0000-1000-8000-00805f9b34fb');
  static final Guid chrPlxCont = Guid('00002a5f-0000-1000-8000-00805f9b34fb');
  static final Guid chrPlxSpot = Guid('00002a5e-0000-1000-8000-00805f9b34fb');

  static final Guid chrCde81   = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');

  static final Guid svcFfe0    = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  static final Guid chrFfe4    = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');

  static final Guid svcBody    = Guid('0000181b-0000-1000-8000-00805f9b34fb');
  static final Guid chrBodyMx  = Guid('00002a9c-0000-1000-8000-00805f9b34fb');

  static final Guid chr1530    = Guid('00001530-0000-3512-2118-0009af100700');
  static final Guid chr1531    = Guid('00001531-0000-3512-2118-0009af100700');
  static final Guid chr1532    = Guid('00001532-0000-3512-2118-0009af100700');
  static final Guid chr1542    = Guid('00001542-0000-3512-2118-0009af100700');
  static final Guid chr1543    = Guid('00001543-0000-3512-2118-0009af100700');
  static final Guid chr2A2Fv   = Guid('00002a2f-0000-3512-2118-0009af100700');

  static final Guid svcFfb0    = Guid('0000ffb0-0000-1000-8000-00805f9b34fb');
  static final Guid svcFee0    = Guid('0000fee0-0000-1000-8000-00805f9b34fb');

  static final Guid svcFff0    = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
  static final Guid haChrFff1 = Guid('0000fff1-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid haChrFff2 = Guid('0000fff2-0000-1000-8000-00805f9b34fb'); // write/wwr

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupByService());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connMon?.cancel();
    _bfs710?.stop();
    _fr400?.dispose();
    super.dispose();
  }

  Future<void> _setupByService() async {
    try {
      _error = null;
      if (mounted) {
        setState(() {
          // ล้างค่าค้างทุกครั้งที่เริ่ม detect service
          // กัน temp จากอุปกรณ์ก่อนหน้าติดมาที่ YX110
          _latestData.clear();
        });
      }

      try { await FlutterBluePlus.stopScan(); } catch (_) {}
      try { await widget.device.requestMtu(247); } catch (_) {}

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

      // discover (retry สั้น ๆ เผื่อ BLE ช้า)
      _services = [];
      for (int i = 0; i < 3; i++) {
        _services = await widget.device.discoverServices();
        if (_services.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final lowerName = widget.device.platformName.toLowerCase();

      // ==== flags/booleans ช่วยตัดสินใจ ====
      final hasFff0      = _hasSvc(svcFff0);
      final hasStdThermo = _hasSvc(svcThermo) && _hasChr(svcThermo, chrTemp);
      final hasStdBp     = _hasSvc(svcBp) && _hasChr(svcBp, chrBpMeas);
      final hasHaVendor  = hasFff0 && (_hasChr(svcFff0, haChrFff1) || _hasChr(svcFff0, haChrFff2));

      final isFr400Name  = lowerName.contains('fr400') ||
                           lowerName.contains('jpd-fr400') ||
                           lowerName.contains('jpd fr400') ||
                           lowerName.contains('jpdfr400');

      final isHa120Name  = lowerName.contains('ha120') || lowerName.contains('jpd-ha120');

      final maybeThermoByName = lowerName.contains('therm') || isFr400Name ||
                                (lowerName.contains('jumper') && !isHa120Name);

      // ===================== ลำดับตรวจจับ =====================

      // (0) FR400 — จับแบบชัดเจน: ชื่อเข้าข่าย + มี FFF0 + ไม่ใช่ Thermo/BP มาตรฐาน
      if (_hasSvc(svcFff0)) {
        final hasStdThermo0 = _hasSvc(svcThermo) && _hasChr(svcThermo, chrTemp);
        final hasStdBp0     = _hasSvc(svcBp) && _hasChr(svcBp, chrBpMeas);
        if (!hasStdThermo0 && !hasStdBp0) {
          final s = JumperFr400(device: widget.device).parse;
          _sub?.cancel();
          _sub = s.listen(_onData, onError: _onErr);  // จะได้ทั้ง temp และ raw/src (ถ้า parser ส่งมา)
          _monitorDisconnect();
          return;
        }
      }

      // (1) HA120 — vendor FFF0 (จับทั้งจากชื่อและลักษณะ service/char)
      if (isHa120Name || hasHaVendor) {
        final s = await JumperJpdHa120(device: widget.device).parse();
        _listenMapStream(s);
        _monitorDisconnect();
        return;
      }

      // (2) Thermometer (มาตรฐาน) — ถ้ามี 1809/2A1C ให้ใช้ก่อน
      if (hasStdThermo) {
        final s = await YuwellYhw6(device: widget.device).parse();
        _sub?.cancel();
        _sub = s.listen(
          (t) => _onData({'temp': t.toStringAsFixed(2)}),
          onError: _onErr,
        );
        _monitorDisconnect();
        return;
      }

      // (3) FR400 (fallback) — มี FFF0, เดาว่าเป็น Thermo, ไม่ใช่ BP มาตรฐาน
      if (hasFff0 && !hasStdThermo && !hasStdBp && maybeThermoByName) {
        _fr400 = JumperFr400(device: widget.device);
        await _fr400!.start();
        _sub?.cancel();
        _sub = _fr400!.onTemperature.listen(
          (c) => _onData({'temp': c.toStringAsFixed(1)}),
          onError: _onErr,
        );
        _monitorDisconnect();
        return;
      }

      // (4) Jumper oximeter — ล็อก chrCDEACB81
      if (_hasAnyChar(chrCde81)) {
        final s = await JumperPoJpd500f(device: widget.device).parse();
        _listenMapStream(s); _monitorDisconnect(); return;
      }

      // (5) PLX (ถ้าคุณประกาศ svcPlx/chrPlx* ไว้ในไฟล์)
      if (_hasSvc(svcPlx) && (_hasChr(svcPlx, chrPlxCont) || _hasChr(svcPlx, chrPlxSpot))) {
        final s = await JumperPoJpd500f(device: widget.device).parse();
        _listenMapStream(s); _monitorDisconnect(); return;
      }

      // (6) Yuwell oximeter FFE0/FFE4
      if (_hasSvc(svcFfe0) && _hasChr(svcFfe0, chrFfe4)) {
        final s = await YuwellFpoYx110(device: widget.device).parse();
        _listenMapStream(s); _monitorDisconnect(); return;
      }

      // (7) BP (มาตรฐาน)
      if (hasStdBp) {
        final s = await AdUa651Ble(device: widget.device).parse();
        _listenBpStream(s); _monitorDisconnect(); return;
      }

      // (8) Mi Body Scale / Xiaomi proprietary
      final hasMibfs =
          _hasSvc(svcBody) || _hasChr(svcBody, chrBodyMx) ||
          _hasAnyChar(chr1530) || _hasAnyChar(chr1531) ||
          _hasAnyChar(chr1532) || _hasAnyChar(chr1542) ||
          _hasAnyChar(chr1543) || _hasAnyChar(chr2A2Fv);
      if (hasMibfs) {
        final s = await MiBfs05hm(device: widget.device).parse();
        _listenMapStream(s); _monitorDisconnect(); return;
      }

      // (9) Glucose (มาตรฐาน) — ดึง record ล่าสุดแบบเร็ว
      if (_hasSvc(svcGlucose) && _hasChr(svcGlucose, chrGluMeas) && _hasChr(svcGlucose, chrGluRacp)) {
        final yg = YuwellGlucose(device: widget.device);
        _sub?.cancel();
        _sub = Stream.fromFuture(yg.getLatestRecord()).listen((m) {
          final mgdl = m['mgdl'] ?? '0';
          final mmol = (double.tryParse(mgdl) ?? 0) / 18.015;
          _onData({
            'mgdl': mgdl,
            'mmol': mmol.toStringAsFixed(1),
            // m มี 'time', 'seq' เผื่ออยากแสดงเพิ่ม
          });
        }, onError: _onErr);
        _monitorDisconnect();
        return;
      }

      // (10) Beurer BM57 (BP)
      if (lowerName.contains('bm57') && hasStdBp) {
        _bm57 = BeurerBm57(device: widget.device);
        await _bm57!.start();
        _sub?.cancel();
        _sub = _bm57!.onBloodPressure.listen((m) => _onData(m), onError: _onErr);
        _monitorDisconnect();
        return;
      }

      // ===== ถ้าไม่เข้าเคสใดเลย =====
      _error = 'ยังจำแนกอุปกรณ์ไม่สำเร็จ (ไม่พบ Characteristic/Service ที่รองรับ)\n'
               'ดูรายการ Service/Characteristic ด้านล่างเพื่อตรวจสอบ UUID';
      if (mounted) setState(() {});
    } catch (e) {
      _onErr(e);
    }
  }

  void _monitorDisconnect() {
    _connMon?.cancel();
    _connMon = widget.device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อุปกรณ์ตัดการเชื่อมต่อ')),
        );
      }
    });
  }

  void _startGlucose() {
    // กันซ้อน
    _gluSub?.cancel();

    final yg = YuwellGlucose(device: widget.device);

    // ดึงทั้งหมด (ย้อนหลัง) ถ้าต้องการล่าสุดอย่างเดียวเปลี่ยนเป็น true
    _gluSub = yg.parse(fetchLastOnly: false).listen((mgStr) {
      final mgdl = double.tryParse(mgStr) ?? 0.0;
      final mmol = mgdl / 18.015;

      _onData({
        'mgdl': mgdl.toStringAsFixed(0),
        'mmol': mmol.toStringAsFixed(1),
      });
    }, onError: (e) {
      _onErr('GLUCOSE: $e');
    });
  }

  // helpers
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

  // merge ทับค่าเดิม ป้องกัน mgdl หายเมื่อมี RACP เด้งมา
  void _onData(Map<String, String> data) {
    if (!mounted) return;
    setState(() {
      final merged = {..._latestData};

      // ถ้าเป็นสัญญาณจาก Yuwell FPO/YX110 ห้ามให้คีย์อุณหภูมิเล็ดลอด
      final src = (data['src'] ?? '').toLowerCase();
      if (src.contains('yx110')) {
        merged.remove('temp');
        merged.remove('temp_c');
        merged.remove('temperature');
      }

      merged.addAll(data);
      _latestData = merged;
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

  Widget _glucosePanel(Map<String, String> data) {
    final mgdl = data['mgdl'] ?? '-';
    final mmol = data['mmol'] ?? '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Glucose', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('mg/dL: $mgdl'),
            Text('mmol/L: $mmol'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : widget.device.remoteId.str;

    final mgdl = _latestData['mgdl'];
    final mmol = _latestData['mmol'];
    final showGlu = (mgdl != null && mgdl != '0') || (mmol != null && mmol != '0.0');

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _setupByService, tooltip: 'ลองค้นหา Service ใหม่'),
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
                    if (showGlu) ...[
                      Text('${mgdl ?? '-'} mg/dL',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                      if (mmol != null)
                        Text('$mmol mmol/L', style: const TextStyle(fontSize: 18)),
                      const Divider(),
                    ],

                    if (_latestData['weight_kg'] != null) ...[
                      Text('${_latestData['weight_kg']} kg',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                      if (_latestData['bmi'] != null)
                        Text('BMI: ${_latestData['bmi']}', style: const TextStyle(fontSize: 18)),
                      const Divider(),
                    ],

                    // แสดงอุณหภูมิเมื่อมีค่า และไม่ใช่เหตุการณ์จาก YX110
                    if (_latestData['temp'] != null &&
                        !((_latestData['src'] ?? '').toLowerCase().contains('yx110'))) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.thermostat, size: 28),
                          const SizedBox(width: 8),
                          Text('${_latestData['temp']} °C',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Divider(),
                    ],

                    Builder(builder: (_) {
                      final spo2Val = _validSpo2(
                        _latestData['spo2'] ?? _latestData['SpO2'] ?? _latestData['SPO2'],
                      );
                      final prVal = _validPr(
                        _latestData['pr'] ?? _latestData['PR'] ?? _latestData['pulse'],
                      );
                      if (spo2Val != null || prVal != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SpO₂: ${spo2Val?.toString() ?? '-'} %',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Pulse: ${prVal?.toString() ?? '-'} bpm',
                                style: const TextStyle(fontSize: 20)),
                            const Divider(),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    ..._latestData.entries
                        .where((e) => !{
                              'weight_kg','bmi','impedance_ohm',
                              'spo2','SpO2','SPO2',
                              'pr','PR','pulse',
                              'temp','temp_c','temperature',
                              'mgdl','mmol','seq','ts','time_offset',
                              'racp','racp_num','src','raw',
                            }.contains(e.key))
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 14)),
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
                                    Text('Service: ${s.uuid.str}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    ...s.characteristics.map((c) => Text(
                                          '  • Char: ${c.uuid.str}  '
                                          '${c.properties.notify ? "[notify]" : ""}'
                                          '${c.properties.indicate ? "[indicate]" : ""}',
                                        )),
                                  ],
                                ),
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
