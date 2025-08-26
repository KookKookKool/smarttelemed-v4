// lib/core/device/dashboard/devices_inline_section.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smarttelemed_v4/core/device/session/device_session.dart';
import 'package:smarttelemed_v4/core/device/session/pick_parser.dart';
import 'package:smarttelemed_v4/core/device/dashboard/device_detail_page.dart';

class DevicesInlineSection extends StatefulWidget {
  const DevicesInlineSection({
    super.key,
    this.title = 'Devices',
    this.showHeader = true,
    this.showSpinner = true,
  });

  final String title;
  final bool showHeader;
  final bool showSpinner;

  @override
  State<DevicesInlineSection> createState() => _DevicesInlineSectionState();
}

class _DevicesInlineSectionState extends State<DevicesInlineSection> {
  // ===== state =====
  final Map<String, DeviceSession> _sessions = {};
  Set<String> _installedIds = {}; // ว่าง = อนุญาตทุกเครื่องที่รองรับ

  // scan / auto-connect
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _scanFlagSub;
  bool _isScanning = false;
  final Queue<String> _autoQ = Queue<String>();
  bool _autoBusy = false;
  final Map<String, DateTime> _lastTry = {};
  static const _cooldown = Duration(seconds: 20);

  // background scan
  Timer? _scanTimer;

  // allow-list แบบหลวม (ชื่อ + service tails)
  static const Set<String> _supportedServiceTails = {
    '1822', '1810', '1809', '1808', '181b', 'fff0', 'ffe0', 'ffb0', 'fee0',
  };
  static const List<String> _nameKeywords = [
    'ye680', 'ua-651', 'ua651', 'ha120', 'bm57',
    'oximeter','spo','yx110','jumper','jpd','fr400','thermo','ft95','yuwell',
    'glucose','mibfs','scale','bfs','swan'
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _installedIds = await _loadInstalledIds();
    await _seedFromConnected();
    _startBackgroundScan();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scanSub?.cancel();
    _scanFlagSub?.cancel();
    for (final s in _sessions.values) {
      s.dispose();
    }
    super.dispose();
  }

  // ===== installed ids (optional) =====
  Future<Set<String>> _loadInstalledIds() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList('installed_device_ids') ?? const <String>[])
          .where((e) => e.trim().isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // ===== bootstrap: current connected =====
  Future<void> _seedFromConnected() async {
    final devs = await FlutterBluePlus.connectedDevices;
    for (final d in devs) {
      if (_installedIds.isNotEmpty && !_installedIds.contains(d.remoteId.str)) continue;
      if (!_sessions.containsKey(d.remoteId.str)) {
        await _startSessionFor(d);
      }
    }
  }

  // ===== background scan only =====
  void _startBackgroundScan() {
    _scanTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_isScanning) _startScan();
    });
  }

  void _startScan() async {
    await _scanSub?.cancel();
    await _scanFlagSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      final now = DateTime.now();
      for (final r in results) {
        final id = r.device.remoteId.str;

        if (_installedIds.isNotEmpty && !_installedIds.contains(id)) continue;
        if (!_looksSupported(r)) continue;

        final t = _lastTry[id];
        if (t != null && now.difference(t) < _cooldown) continue;

        final connectedNow = await r.device.connectionState.first == BluetoothConnectionState.connected;
        if (!connectedNow && !_sessions.containsKey(id)) {
          _lastTry[id] = now;
          _enqueue(r.device);
        }
      }
    });

    _scanFlagSub = FlutterBluePlus.isScanning.listen((s) {
      if (mounted) setState(() => _isScanning = s);
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (_) {}
  }

  bool _looksSupported(ScanResult r) {
    final name =
        (r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName).toLowerCase();
    if (name.isNotEmpty && _nameKeywords.any((k) => name.contains(k))) return true;

    for (final g in r.advertisementData.serviceUuids) {
      final s = g.str.toLowerCase();
      final tail = s.length >= 4 ? s.substring(s.length - 4) : s;
      if (_supportedServiceTails.contains(tail)) return true;
    }
    final isXiaomi = r.advertisementData.manufacturerData.keys.contains(0x0157);
    final hasBody = r.advertisementData.serviceUuids.any((g) => g.str.toLowerCase().endsWith('181b'));
    if (isXiaomi && hasBody) return true;

    return false;
  }

  void _enqueue(BluetoothDevice d) {
    final id = d.remoteId.str;
    if (_autoQ.contains(id)) return;
    _autoQ.add(id);
    _drainAutoQ();
  }

  Future<void> _drainAutoQ() async {
    if (_autoBusy) return;
    _autoBusy = true;
    try {
      while (_autoQ.isNotEmpty && mounted) {
        final id = _autoQ.removeFirst();
        final dev = BluetoothDevice.fromId(id);
        final wasScanning = _isScanning;
        try {
          if (wasScanning) {
            try {
              await FlutterBluePlus.stopScan();
            } catch (_) {}
          }
          await dev.connect(autoConnect: false, timeout: const Duration(seconds: 12));
          await _startSessionFor(dev);
        } catch (_) {
          // เงียบไว้
        } finally {
          if (wasScanning) _startScan();
        }
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } finally {
      _autoBusy = false;
    }
  }

  // ===== session =====
  Future<void> _startSessionFor(BluetoothDevice d) async {
    final id = d.remoteId.str;
    if (_sessions.containsKey(id)) return;

    final sess = DeviceSession(
      device: d,
      onUpdate: () => mounted ? setState(() {}) : null,
      onError: (_) => mounted ? setState(() {}) : null,
      onDisconnected: () async {
        // ⬇️ หายไปทันทีเมื่อไม่ได้เชื่อมต่อ
        _removeSession(id);
      },
    );
    _sessions[id] = sess;
    await sess.start(pickParser: pickParser);
    if (mounted) setState(() {});
  }

  void _removeSession(String id) {
    final s = _sessions.remove(id);
    s?.dispose();
    if (mounted) setState(() {});
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final items = _sessions.values.toList()
      ..sort((a, b) => _guessTitle(a).compareTo(_guessTitle(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (widget.showSpinner && _isScanning) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (items.isEmpty)
          const SizedBox.shrink()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _PrettyDeviceCard(
              session: items[i],
              onOpen: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeviceDetailPage.byId(items[i].device.remoteId.str),
                  ),
                );
              },
              onDisconnect: () async {
                try {
                  await items[i].device.disconnect();
                } catch (_) {}
                // onDisconnected ใน session จะลบการ์ดให้อัตโนมัติ
              },
            ),
          ),
      ],
    );
  }

  // ===== heuristic titles (TH) =====
  String _guessTitle(DeviceSession s) {
    final name = s.device.platformName.toLowerCase();
    final m = s.latestData;

    if ((m['sys'] ?? m['systolic']) != null && (m['dia'] ?? m['diastolic']) != null) {
      return 'เครื่องวัดความดัน';
    }
    if ((m['spo2'] ?? m['SpO2'] ?? m['SPO2']) != null || name.contains('oxi') || name.contains('spo')) {
      return 'เครื่องวัดออกซิเจนปลายนิ้ว';
    }
    if ((m['temp'] ?? m['temp_c']) != null || name.contains('therm') || name.contains('fr400') || name.contains('ft95')) {
      return 'เครื่องวัดอุณหภูมิ';
    }
    if (m['mgdl'] != null || name.contains('glucose')) {
      return 'เครื่องวัดน้ำตาล';
    }
    if (m['weight_kg'] != null || name.contains('scale') || name.contains('bfs')) {
      return 'เครื่องชั่งน้ำหนัก';
    }
    return s.device.platformName.isNotEmpty ? s.device.platformName : s.device.remoteId.str;
  }
}

// ───────────────────────────────────────────
// การ์ดสไตล์ภาพตัวอย่าง (ไม่มีปุ่มเชื่อมต่อ/เพิ่ม)
// ───────────────────────────────────────────
class _PrettyDeviceCard extends StatelessWidget {
  const _PrettyDeviceCard({
    required this.session,
    required this.onOpen,
    required this.onDisconnect,
  });

  final DeviceSession session;
  final VoidCallback onOpen;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final m = session.latestData;
    final titleTh = _title(session, m);
    final subtitle = _subtitle(session);
    final kind = _kind(m, session.device.platformName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _leading(kind),
              const SizedBox(width: 16),
              Expanded(child: _texts(titleTh, subtitle)),
              const SizedBox(width: 8),
              _values(kind, m),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- pieces ----------
  Widget _leading(_Kind kind) {
    String? asset;
    switch (kind) {
      case _Kind.bp:
        asset = 'assets/devices/bp.jpg';
        break;
      case _Kind.spo2:
        asset = 'assets/devices/spo2.jpg';
        break;
      case _Kind.temp:
        asset = 'assets/devices/thermo.jpg';
        break;
      case _Kind.glucose:
        asset = 'assets/devices/glucose.jpg';
        break;
      case _Kind.scale:
        asset = 'assets/devices/scale.png';
        break;
      case _Kind.unknown:
        asset = null;
        break;
    }
    Widget fallback = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.devices_other, size: 36, color: Colors.black38),
    );

    if (asset == null) return fallback;
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }

  Widget _texts(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.0)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  Widget _values(_Kind kind, Map<String, String> m) {
    switch (kind) {
      case _Kind.bp:
        final sys = m['sys'] ?? m['systolic'] ?? '--';
        final dia = m['dia'] ?? m['diastolic'] ?? '--';
        final pr = m['pul'] ?? m['pr'] ?? m['PR'] ?? m['pulse'];
        return _bpBlock(sys, dia, pr);
      case _Kind.spo2:
        final spo2 = m['spo2'] ?? m['SpO2'] ?? m['SPO2'] ?? '--';
        final pr = m['pr'] ?? m['PR'] ?? m['pulse'];
        return _spo2Block(spo2, pr);
      case _Kind.temp:
        final t = m['temp'] ?? m['temp_c'] ?? '--';
        return _bigBlock(t, '°C', foot: '*C');
      case _Kind.glucose:
        final g = m['mgdl'] ?? m['dtx'] ?? '--';
        return _bigBlock(g, 'mg%');
      case _Kind.scale:
        final w = m['weight_kg'] ?? '--';
        return _bigBlock(w, 'kg');
      case _Kind.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _bpBlock(String sys, String dia, String? pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black),
            children: [
              TextSpan(text: sys, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const TextSpan(text: ' / ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              TextSpan(text: dia, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('(${pr ?? '--'})', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            const Text('mmHg', style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(width: 14),
            const Text('bpm', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _spo2Block(String spo2, String? pr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(spo2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('%', style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(width: 18),
            Text('bpm', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
        if (pr != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(pr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _bigBlock(String val, String unit, {String? foot}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(unit, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            if (foot != null) ...[
              const SizedBox(width: 6),
              Text(foot, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ],
          ],
        ),
      ],
    );
  }

  _Kind _kind(Map<String, String> m, String name) {
    final lc = name.toLowerCase();
    if ((m['sys'] ?? m['systolic']) != null && (m['dia'] ?? m['diastolic']) != null) return _Kind.bp;
    if ((m['spo2'] ?? m['SpO2'] ?? m['SPO2']) != null) return _Kind.spo2;
    if ((m['temp'] ?? m['temp_c']) != null) return _Kind.temp;
    if (m['mgdl'] != null || lc.contains('glucose')) return _Kind.glucose;
    if (m['weight_kg'] != null) return _Kind.scale;
    return _Kind.unknown;
  }

  String _title(DeviceSession s, Map<String, String> m) {
    switch (_kind(m, s.device.platformName)) {
      case _Kind.bp:
        return 'เครื่องวัดความดัน';
      case _Kind.spo2:
        return 'เครื่องวัดออกซิเจนปลายนิ้ว';
      case _Kind.temp:
        return 'เครื่องวัดอุณหภูมิ';
      case _Kind.glucose:
        return 'เครื่องวัดน้ำตาล';
      case _Kind.scale:
        return 'เครื่องชั่งน้ำหนัก';
      case _Kind.unknown:
        return s.device.platformName.isNotEmpty ? s.device.platformName : s.device.remoteId.str;
    }
  }

  String _subtitle(DeviceSession s) {
    final p = s.device.platformName.trim();
    if (p.isNotEmpty) return p;
    return s.device.remoteId.str;
  }
}

enum _Kind { bp, spo2, temp, glucose, scale, unknown }
