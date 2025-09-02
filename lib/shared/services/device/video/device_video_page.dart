import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:smarttelemed_v4/shared/services/device/dashboard/device_hub.dart';
import 'package:smarttelemed_v4/shared/services/device/session/device_session.dart';

enum DeviceKind { bp, spo2, temp, glucose, scale }

class DeviceVideoPage extends StatefulWidget {
  const DeviceVideoPage({
    super.key,
    required this.kind,
    this.titleHint,
    this.modelHint,
  });

  final DeviceKind kind;
  final String? titleHint;
  final String? modelHint;

  @override
  State<DeviceVideoPage> createState() => _DeviceVideoPageState();
}

class _DeviceVideoPageState extends State<DeviceVideoPage> {
  VideoPlayerController? _vc;
  Future<void>? _initF;
  StreamSubscription? _tick;
  VoidCallback? _hubDetach;

  @override
  void initState() {
    super.initState();
    _setupVideo();
    // ฟัง Hub เพื่ออัปเดตค่าทันทีที่มีการเปลี่ยน
    DeviceHub.I.addListener(_onHubChanged);
    _hubDetach = () => DeviceHub.I.removeListener(_onHubChanged);
    // กันกรณีอัปเดตเงียบ
    _tick = Stream.periodic(const Duration(milliseconds: 500)).listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _onHubChanged() {
    if (mounted) setState(() {});
  }

  void _setupVideo() {
    final asset = _assetFor(widget.kind);
    _vc = VideoPlayerController.asset(asset);
    _initF = _vc!.initialize().then((_) {
      _vc!.setLooping(true);
      _vc!.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _hubDetach?.call();
    _vc?.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  String _assetFor(DeviceKind k) {
    switch (k) {
      case DeviceKind.bp: return 'assets/devices/video/bp.mp4';
      case DeviceKind.spo2: return 'assets/devices/video/spo2.mp4';
      case DeviceKind.temp: return 'assets/devices/video/thermo.mp4';
      case DeviceKind.glucose: return 'assets/devices/video/glucose.mp4';
      case DeviceKind.scale: return 'assets/devices/video/scale.mp4';
    }
  }

  String _titleFor(DeviceKind k) {
    switch (k) {
      case DeviceKind.bp: return 'เครื่องวัดความดัน';
      case DeviceKind.spo2: return 'เครื่องวัดออกซิเจนปลายนิ้ว';
      case DeviceKind.temp: return 'เครื่องวัดอุณหภูมิ';
      case DeviceKind.glucose: return 'เครื่องวัดน้ำตาล';
      case DeviceKind.scale: return 'เครื่องชั่งน้ำหนัก';
    }
  }

  // ------------ ดึงค่าล่าสุดจาก sessions ของ Hub ตามชนิด ------------
  Map<String, String> _latestFor(DeviceKind kind) {
    final sessions = DeviceHub.I.sessions;
    DeviceSession? pick;
    for (final s in sessions) {
      final m = s.latestData;
      if (m.isEmpty) continue;
      switch (kind) {
        case DeviceKind.bp:
          if ((m['sys'] ?? m['systolic']) != null && (m['dia'] ?? m['diastolic']) != null) pick = s;
          break;
        case DeviceKind.spo2:
          if ((m['spo2'] ?? m['SpO2'] ?? m['SPO2']) != null) pick = s;
          break;
        case DeviceKind.temp:
          if ((m['temp'] ?? m['temp_c'] ?? m['temperature']) != null) pick = s;
          break;
        case DeviceKind.glucose:
          if (m['mgdl'] != null || m['mmol'] != null) pick = s;
          break;
        case DeviceKind.scale:
          if (m['weight_kg'] != null || m['weight'] != null) pick = s;
          break;
      }
      if (pick != null) break;
    }
    return pick?.latestData ?? const <String, String>{};
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.titleHint ?? _titleFor(widget.kind);
    final model = widget.modelHint ?? '';

    final m = _latestFor(widget.kind);
    const indigo = Color(0xFF1F1D59);

    Widget values;
    switch (widget.kind) {
      case DeviceKind.bp:
        final sys = m['sys'] ?? m['systolic'] ?? '--';
        final dia = m['dia'] ?? m['diastolic'] ?? '--';
        final pr  = m['pul'] ?? m['PR'] ?? m['pr'] ?? m['pulse'] ?? '--';
        values = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: const [
              SizedBox(height: 4),
              Text('mmHg', style: TextStyle(fontSize: 16)),
            ]),
            const SizedBox(width: 12),
            Row(children: [
              Text(sys, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
              const SizedBox(width: 8),
              const Text('/', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
              const SizedBox(width: 8),
              Text(dia, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
            ]),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(pr, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: indigo)),
              const SizedBox(height: 4),
              const Text('bpm', style: TextStyle(fontSize: 16)),
            ]),
          ],
        );
        break;

      case DeviceKind.spo2:
        final spo2 = m['spo2'] ?? m['SpO2'] ?? m['SPO2'] ?? '--';
        final pr   = m['pr'] ?? m['PR'] ?? m['pulse'] ?? '--';
        values = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(spo2, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
            const SizedBox(height: 4),
            const Text('%', style: TextStyle(fontSize: 16)),
          ]),
          const SizedBox(width: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(pr, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: indigo)),
            const SizedBox(height: 4),
            const Text('bpm', style: TextStyle(fontSize: 16)),
          ]),
        ]);
        break;

      case DeviceKind.temp:
        final t = m['temp'] ?? m['temp_c'] ?? m['temperature'] ?? '--';
        values = Column(
          children: [
            Text(t, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
            const SizedBox(height: 4),
            const Text('°C', style: TextStyle(fontSize: 16)),
          ],
        );
        break;

      case DeviceKind.glucose:
        final g  = m['mgdl'] ?? '--';
        final mm = m['mmol'];
        values = Column(
          children: [
            Text(g, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
            const SizedBox(height: 4),
            const Text('mg/dL', style: TextStyle(fontSize: 16)),
            if (mm != null) ...[
              const SizedBox(height: 8),
              Text(mm, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: indigo)),
              const SizedBox(height: 2),
              const Text('mmol/L', style: TextStyle(fontSize: 16)),
            ]
          ],
        );
        break;

      case DeviceKind.scale:
        final w = m['weight_kg'] ?? m['weight'] ?? '--';
        values = Column(
          children: [
            Text(w, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: indigo)),
            const SizedBox(height: 4),
            const Text('kg', style: TextStyle(fontSize: 16)),
          ],
        );
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
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
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // video block
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FutureBuilder(
                    future: _initF,
                    builder: (_, snap) {
                      if (snap.connectionState != ConnectionState.done || _vc == null || !_vc!.value.isInitialized) {
                        return const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator()));
                      }
                      return AspectRatio(
                        aspectRatio: _vc!.value.aspectRatio,
                        child: VideoPlayer(_vc!),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // subtitle/model
            if ((widget.modelHint ?? '').isNotEmpty)
              Text(widget.modelHint!, style: const TextStyle(fontSize: 16, color: Colors.black54)),

            const SizedBox(height: 16),

            // values
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: values,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
