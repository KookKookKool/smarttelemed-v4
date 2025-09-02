// lib/core/device/dashboard/device_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

// ใช้ของที่คุณทำไว้แล้ว
import 'package:smarttelemed_v4/shared/screens/device/session/device_session.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/pick_parser.dart';
import 'package:smarttelemed_v4/shared/screens/device/ui/device_card.dart';

// ไปหน้าอื่น
import 'package:smarttelemed_v4/shared/screens/device/connect/device_connect.dart';
import 'package:smarttelemed_v4/shared/screens/device/connect/check conncet/device_page.dart';

/// พาเนลแบบฝังในหน้าอื่น ๆ ได้ (ไม่มี Scaffold)
class DeviceCardsPanel extends StatefulWidget {
  const DeviceCardsPanel({super.key, this.title = 'อุปกรณ์ที่เชื่อมต่อ'});
  final String title;

  @override
  State<DeviceCardsPanel> createState() => _DeviceCardsPanelState();
}

class _DeviceCardsPanelState extends State<DeviceCardsPanel> {
  final Map<String, DeviceSession> _sessions = {};
  bool _loading = false;

  Timer? _pollTimer;        // โพลล์รายชื่ออุปกรณ์ที่เชื่อมต่อ
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshConnected();
    // โพลล์เบา ๆ ทุก 2 วิ (สั้นและพอเพียง)
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_refreshing) _refreshConnected();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final s in _sessions.values) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshConnected() async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) setState(() => _loading = true);

    try {
      final devs = await FlutterBluePlus.connectedDevices;

      // เพิ่ม session ให้ device ใหม่
      for (final d in devs) {
        if (!_sessions.containsKey(d.remoteId.str)) {
          await _startSessionFor(d);
        }
      }

      // ลบ session ที่ไม่ได้ต่อแล้ว
      final alive = devs.map((e) => e.remoteId.str).toSet();
      final gone = _sessions.keys.where((k) => !alive.contains(k)).toList();
      for (final id in gone) {
        _sessions[id]?.dispose();
        _sessions.remove(id);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _refreshing = false;
    }
  }

  Future<void> _startSessionFor(BluetoothDevice d) async {
    final id = d.remoteId.str;
    if (_sessions.containsKey(id)) return;

    final sess = DeviceSession(
      device: d,
      onUpdate: () => mounted ? setState(() {}) : null,
      onError: (_)  => mounted ? setState(() {}) : null,
      onDisconnected: () async {
        // หลุดปุ๊บเอาออกเลย
        _sessions[id]?.dispose();
        _sessions.remove(id);
        if (mounted) setState(() {});
      },
    );

    _sessions[id] = sess;
    await sess.start(pickParser: pickParser);   // ← ใช้ตัวเลือก parser กลางของคุณ
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _sessions.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // เฮดเดอร์ + ปุ่ม
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                tooltip: 'รีเฟรช',
                icon: const Icon(Icons.refresh),
                onPressed: _refreshConnected,
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceConnectPage()),
                  );
                  if (!mounted) return;
                  await _refreshConnected();
                },
                icon: const Icon(Icons.add_link),
                label: const Text('เชื่อมต่ออุปกรณ์'),
              ),
            ],
          ),
        ),

        if (_loading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('ยังไม่พบอุปกรณ์ที่เชื่อมต่อ'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final s = items[i];
              return DeviceCard(
                session: s,
                onOpen: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DevicePage(device: s.device)),
                  );
                },
                onDisconnect: () async {
                  try { await s.device.disconnect(); } catch (_) {}
                  await _refreshConnected();
                },
              );
            },
          ),
      ],
    );
  }
}

/// หน้าเต็ม (มี AppBar) — เอา Panel ด้านบนมาใส่เฉย ๆ
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อุปกรณ์ที่เชื่อมต่อ')),
      body: const SingleChildScrollView(
        child: DeviceCardsPanel(),
      ),
    );
  }
}
