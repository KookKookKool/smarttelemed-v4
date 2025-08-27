// lib/core/device/dashboard/device_detail_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

import 'package:smarttelemed_v4/core/device/session/device_session.dart';
import 'package:smarttelemed_v4/core/device/session/pick_parser.dart';
import 'package:smarttelemed_v4/core/device/dashboard/device_hub.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage.session(this.session, {super.key}) : deviceId = null;
  const DeviceDetailPage.byId(this.deviceId, {super.key}) : session = null;

  final DeviceSession? session;
  final String? deviceId;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  DeviceSession? _session;
  bool _ownedSession = false; // เราสร้างเองหรือยืมจาก Hub
  StreamSubscription? _tick;
  VoidCallback? _hubListenCancel;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) ถ้าส่ง session มาโดยตรง → ใช้เลย
    if (widget.session != null) {
      _session = widget.session;
    } else {
      final id = widget.deviceId!;
      // 2) ลองยืม session จาก Hub ก่อน
      final fromHub = DeviceHub.I.sessionById(id);
      if (fromHub != null) {
        _session = fromHub;
      } else {
        // 3) ไม่มีใน Hub → สร้าง session ชั่วคราวเอง
        final connected = await FlutterBluePlus.connectedDevices;
        BluetoothDevice dev = connected.firstWhere(
          (d) => d.remoteId.str == id,
          orElse: () => BluetoothDevice.fromId(id),
        );
        final st = await dev.connectionState.first;
        if (st != BluetoothConnectionState.connected) {
          try { await dev.connect(autoConnect: false, timeout: const Duration(seconds: 12)); } catch (_) {}
        }

        final s = DeviceSession(
          device: dev,
          onUpdate: () => mounted ? setState(() {}) : null,
          onError: (_) => mounted ? setState(() {}) : null,
          onDisconnected: () async { if (mounted) setState(() {}); },
        );
        await s.start(pickParser: pickParser);
        _session = s;
        _ownedSession = true;
      }
    }

    // ฟัง Hub เพื่อรีเฟรช UI เมื่อค่าข้างในขยับ (กรณีใช้ session จาก Hub)
    _hubListenCancel = () {
      // detach
      DeviceHub.I.removeListener(_onHubChanged);
    };
    DeviceHub.I.addListener(_onHubChanged);

    // กันกรณี onUpdate ไม่ทันเด้ง
    _tick = Stream.periodic(const Duration(milliseconds: 500)).listen((_) {
      if (mounted) setState(() {});
    });

    if (mounted) setState(() {});
  }

  void _onHubChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _hubListenCancel?.call();
    // ถ้า session เราสร้างเอง → ปิดให้
    if (_ownedSession) {
      _session?.dispose();
    }
    super.dispose();
  }

  // ---------- helpers ----------
  int? _toInt(String? s) => s == null ? null : int.tryParse(s);
  double? _toDouble(String? s) => s == null ? null : double.tryParse(s);

  String _deviceTitle(DeviceSession s) =>
      s.device.platformName.isNotEmpty ? s.device.platformName : s.device.remoteId.str;

  _Kind _kind(Map<String, String> m, String name) {
    final n = name.toLowerCase();
    if ((m['sys'] ?? m['systolic']) != null && (m['dia'] ?? m['diastolic']) != null) return _Kind.bp;
    if ((m['spo2'] ?? m['SpO2'] ?? m['SPO2']) != null) return _Kind.spo2;
    if ((m['temp'] ?? m['temp_c'] ?? m['temperature'] ?? m['temp_f']) != null) return _Kind.temp;
    if (m['mgdl'] != null || m['mmol'] != null || n.contains('glucose')) return _Kind.glucose;
    if (m['weight_kg'] != null || n.contains('scale') || n.contains('bfs')) return _Kind.scale;
    return _Kind.unknown;
  }

  String _titleFor(_Kind k) {
    switch (k) {
      case _Kind.bp: return 'เครื่องวัดความดัน';
      case _Kind.spo2: return 'เครื่องวัดออกซิเจนปลายนิ้ว';
      case _Kind.temp: return 'เครื่องวัดอุณหภูมิ';
      case _Kind.glucose: return 'เครื่องวัดน้ำตาล';
      case _Kind.scale: return 'เครื่องชั่งน้ำหนัก';
      case _Kind.unknown: return 'อุปกรณ์สุขภาพ';
    }
  }

  String _assetFor(_Kind k) {
    switch (k) {
      case _Kind.bp: return 'assets/devices/bp.png';
      case _Kind.spo2: return 'assets/devices/spo2.png';
      case _Kind.temp: return 'assets/devices/thermo.png';
      case _Kind.glucose: return 'assets/devices/glucose.png';
      case _Kind.scale: return 'assets/devices/scale.png';
      case _Kind.unknown: return 'assets/devices/unknown.png';
    }
  }

  String _bpStatus(int? sys, int? dia) {
    if (sys == null || dia == null) return '—';
    if (sys < 120 && dia < 80) return 'ความดันเหมาะสม';
    if (sys < 140 && dia < 90) return 'ความดันปกติ';
    if (sys < 140 || dia < 100) return 'ความดันสูง';
    return 'ความดันสูงมาก';
  }

  String _bpAdvice(String status) {
    switch (status) {
      case 'ความดันเหมาะสม':
      case 'ความดันปกติ':
        return 'คำแนะนำ ควบคุมอาหาร ออกกำลังกายสม่ำเสมอ';
      case 'ความดันสูง':
        return 'คำแนะนำ ลดเค็ม ควบคุมน้ำหนัก ออกกำลังกาย และติดตามต่อเนื่อง';
      default:
        return 'คำแนะนำ พบแพทย์เพื่อตรวจและติดตามอาการอย่างใกล้ชิด';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;

    final bg = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFE9F7F4), Colors.white],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          bg,
          SafeArea(
            child: s == null
                ? const Center(child: CircularProgressIndicator())
                : _content(context, s),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, DeviceSession s) {
    final m = s.latestData;
    final kind = _kind(m, s.device.platformName);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _deviceTitle(s),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final hero = Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              _assetFor(kind),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.devices_other, size: 96, color: Colors.black38),
            ),
          ),
        ),
      ),
    );

    final title = Center(
      child: Column(
        children: [
          Text(_titleFor(kind),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            s.device.platformName.isNotEmpty
                ? s.device.platformName
                : s.device.remoteId.str,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );

    Widget body;
    switch (kind) {
      case _Kind.bp:
        final sys = _toInt(m['sys'] ?? m['systolic']);
        final dia = _toInt(m['dia'] ?? m['diastolic']);
        final pr  = _toInt(m['pul'] ?? m['PR'] ?? m['pr'] ?? m['pulse']);
        final status = _bpStatus(sys, dia);
        final advice = _bpAdvice(status);
        body = _bpSection(sys, dia, pr, status, advice);
        break;

      case _Kind.spo2:
        final spo2 = _toInt(m['spo2'] ?? m['SpO2'] ?? m['SPO2']);
        final pr   = _toInt(m['pr'] ?? m['PR'] ?? m['pulse']);
        body = _spo2Section(spo2, pr);
        break;

      case _Kind.temp:
        final tC = _toDouble(m['temp_c'] ?? m['temp'] ?? m['temperature']);
        final tF = _toDouble(m['temp_f']);
        body = _tempSection(tC: tC, tF: tF);
        break;

      case _Kind.glucose:
        final mgdl = _toDouble(m['mgdl']);
        final mmol = _toDouble(m['mmol']);
        final ts   = m['ts'];
        body = _glucoseSection(mgdl: mgdl, mmol: mmol, when: ts);
        break;

      case _Kind.scale:
        final w = _toDouble(m['weight_kg']);
        final bmi = _toDouble(m['bmi']);
        body = _scaleSection(weightKg: w, bmi: bmi);
        break;

      case _Kind.unknown:
        body = const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('ยังไม่มีข้อมูลจากอุปกรณ์')),
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        hero,
        const SizedBox(height: 14),
        title,
        const SizedBox(height: 12),
        body,
      ],
    );
  }

  // ================== Sections ==================

  Widget _bpSection(int? sys, int? dia, int? pr, String status, String advice) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Center(
          child: Column(
            children: [
              Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF18A05E),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                advice,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _rowValue(
            leftLabel: 'BP',
            main: _bpMain(sys, dia),
            tail: const Text('mmHg', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _rowValue(
            leftLabel: 'PR',
            main: _monoValue(pr),
            tail: const Text('bpm', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ),
      ],
    );
  }

  Widget _spo2Section(int? spo2, int? pr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _rowValue(
            leftLabel: 'SpO₂',
            main: _monoValue(spo2),
            tail: const Text('%', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          const SizedBox(height: 18),
          _rowValue(
            leftLabel: 'PR',
            main: _monoValue(pr),
            tail: const Text('bpm', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _tempSection({double? tC, double? tF}) {
    final showC = tC ?? (tF != null ? (tF - 32) * 5 / 9 : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _rowValue(
            leftLabel: 'Temp',
            main: _monoValue(showC?.toStringAsFixed(1)),
            tail: const Text('°C', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          if (tF != null) ...[
            const SizedBox(height: 12),
            _rowValue(
              leftLabel: '',
              main: _monoValue(tF.toStringAsFixed(1)),
              tail: const Text('°F', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _glucoseSection({double? mgdl, double? mmol, String? when}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _rowValue(
            leftLabel: 'Glu',
            main: _monoValue(mgdl?.toStringAsFixed(0)),
            tail: const Text('mg/dL', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          if (mmol != null) ...[
            const SizedBox(height: 12),
            _rowValue(
              leftLabel: '',
              main: _monoValue(mmol.toStringAsFixed(1)),
              tail: const Text('mmol/L', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ],
          if (when != null && when.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('เวลา: $when', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ]
        ],
      ),
    );
  }

  Widget _scaleSection({double? weightKg, double? bmi}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _rowValue(
            leftLabel: 'Weight',
            main: _monoValue(weightKg?.toStringAsFixed(1)),
            tail: const Text('kg', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          if (bmi != null) ...[
            const SizedBox(height: 12),
            _rowValue(
              leftLabel: 'BMI',
              main: _monoValue(bmi.toStringAsFixed(1)),
              tail: const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  // ================== Atoms ==================

  Widget _rowValue({
    required String leftLabel,
    required Widget main,
    required Widget tail,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(leftLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(child: main),
        const SizedBox(width: 12),
        tail,
      ],
    );
  }

  Widget _bpMain(int? sys, int? dia) {
    final s = (sys?.toString() ?? '--');
    final d = (dia?.toString() ?? '--');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _underNumber(s),
        const SizedBox(width: 8),
        const Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _underNumber(d),
      ],
    );
  }

  Widget _monoValue(dynamic v) =>
      Center(child: _underNumber(v == null ? '--' : v.toString()));

  Widget _underNumber(String s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 80,
          height: 2,
          color: const Color(0xFFE0E0E0),
        ),
      ],
    );
  }
}

enum _Kind { bp, spo2, temp, glucose, scale, unknown }
