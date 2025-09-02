// lib/core/device/dashboard/devices_inline_section.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/device_session.dart';
import 'package:smarttelemed_v4/shared/screens/device/dashboard/device_detail_page.dart';
import 'package:smarttelemed_v4/shared/screens/device/dashboard/device_hub.dart';

class DevicesInlineSection extends StatelessWidget {
  const DevicesInlineSection({
    super.key,
    this.title = 'Devices',
    this.showHeader = true,
  });

  final String title;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DeviceHub.I,
      builder: (_, __) {
        final items = DeviceHub.I.sessions
          ..sort((a, b) => _guessTitle(a).compareTo(_guessTitle(b)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Text('(${items.length})', style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PrettyDeviceCard(
                  session: items[i],
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeviceDetailPage.byId(items[i].device.remoteId.str)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _guessTitle(DeviceSession s) {
    final name = s.device.platformName.toLowerCase();
    final m = s.latestData;
    if ((m['sys'] ?? m['systolic']) != null && (m['dia'] ?? m['diastolic']) != null) return 'เครื่องวัดความดัน';
    if ((m['spo2'] ?? m['SpO2'] ?? m['SPO2']) != null || name.contains('oxi') || name.contains('spo')) {
      return 'เครื่องวัดออกซิเจนปลายนิ้ว';
    }
    if ((m['temp'] ?? m['temp_c']) != null || name.contains('therm') || name.contains('fr400') || name.contains('ft95')) {
      return 'เครื่องวัดอุณหภูมิ';
    }
    if (m['mgdl'] != null || name.contains('glucose')) return 'เครื่องวัดน้ำตาล';
    if (m['weight_kg'] != null || name.contains('scale') || name.contains('bfs')) return 'เครื่องชั่งน้ำหนัก';
    return s.device.platformName.isNotEmpty ? s.device.platformName : s.device.remoteId.str;
  }
}

class _PrettyDeviceCard extends StatelessWidget {
  const _PrettyDeviceCard({
    required this.session,
    required this.onOpen,
  });

  final DeviceSession session;
  final VoidCallback onOpen;

  static const double _cardRadius = 18;
  static const Color _indigo = Color(0xFF1F1D59);

  @override
  Widget build(BuildContext context) {
    final m = session.latestData;
    final titleTh = _title(session, m);
    final subtitle = _subtitle(session);
    final kind = _kind(m, session.device.platformName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: onOpen,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_cardRadius),
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;

                  // ขนาดปรับตามความกว้างจริง (กันล้น)
                  final double thumb = w.clamp(280.0, 480.0) / 4.5; // ~62–106
                  final double gap = w < 360 ? 12 : 18;

                  // ตัวเลขใหญ่—ปรับลดอัตโนมัติ ถ้าจอแคบ
                  final double big = w >= 420 ? 32 : (w >= 360 ? 28 : 24);
                  final double prBig = w >= 420 ? 28 : (w >= 360 ? 24 : 22);
                  const double base = 16; // ฟอนต์มาตรฐาน

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _leading(kind, thumb),
                      SizedBox(width: gap),
                      // ชื่อ/รุ่น (ให้ห่อได้ 2 บรรทัด)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              titleTh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: base, color: Colors.black54, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: gap),
                      // ค่าด้านขวา — ย่อขนาดลงอัตโนมัติเมื่อพื้นที่ไม่พอ
                      Flexible(
                        fit: FlexFit.loose,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _values(kind, m, big: big, prBig: prBig),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ลูกศรชิดมุมขวาบน (ไม่กินพื้นที่ Row)
            const Positioned(
              top: 12,
              right: 12,
              child: Icon(Icons.chevron_right, size: 24, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- pieces ----------
  Widget _leading(_Kind kind, double size) {
    String? asset;
    switch (kind) {
      case _Kind.bp: asset = 'assets/devices/bp.jpg'; break;
      case _Kind.spo2: asset = 'assets/devices/spo2.jpg'; break;
      case _Kind.temp: asset = 'assets/devices/thermo.jpg'; break;
      case _Kind.glucose: asset = 'assets/devices/glucose.jpg'; break;
      case _Kind.scale: asset = 'assets/devices/scale.png'; break;
      case _Kind.unknown: asset = null; break;
    }
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFFF3F6F8), borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.devices_other, size: 36, color: Colors.black38),
    );
    if (asset == null) return fallback;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }

  Widget _values(_Kind kind, Map<String, String> m, {required double big, required double prBig}) {
    switch (kind) {
      case _Kind.bp: {
        final sys = m['sys'] ?? m['systolic'] ?? '--';
        final dia = m['dia'] ?? m['diastolic'] ?? '--';
        final pr  = m['pul'] ?? m['pr'] ?? m['PR'] ?? m['pulse'] ?? '--';
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(sys, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
                    const SizedBox(width: 8),
                    Text('/', style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
                    const SizedBox(width: 8),
                    Text(dia, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('mmHg', style: TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
            const SizedBox(width: 18),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pr, style: TextStyle(fontSize: prBig, fontWeight: FontWeight.w800, color: _indigo)),
                const SizedBox(height: 8),
                const Text('bpm', style: TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ],
        );
      }

      case _Kind.spo2: {
        final spo2 = m['spo2'] ?? m['SpO2'] ?? m['SPO2'] ?? '--';
        final pr   = m['pr'] ?? m['PR'] ?? m['pulse'] ?? '--';
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(spo2, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
                const SizedBox(height: 8),
                const Text('%', style: TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pr, style: TextStyle(fontSize: prBig, fontWeight: FontWeight.w800, color: _indigo)),
                const SizedBox(height: 8),
                const Text('bpm', style: TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ],
        );
      }

      case _Kind.temp: {
        final t = m['temp'] ?? m['temp_c'] ?? '--';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(t, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
            const SizedBox(height: 8),
            const Text('°C', style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        );
      }

      case _Kind.glucose: {
        final g = m['mgdl'] ?? m['dtx'] ?? '--';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(g, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
            const SizedBox(height: 8),
            const Text('mg%', style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        );
      }

      case _Kind.scale: {
        final w = m['weight_kg'] ?? '--';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(w, style: TextStyle(fontSize: big, fontWeight: FontWeight.w800, color: _indigo)),
            const SizedBox(height: 8),
            const Text('kg', style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        );
      }

      case _Kind.unknown:
        return const SizedBox.shrink();
    }
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
      case _Kind.bp: return 'เครื่องวัดความดัน';
      case _Kind.spo2: return 'เครื่องวัดออกซิเจนปลายนิ้ว';
      case _Kind.temp: return 'เครื่องวัดอุณหภูมิ';
      case _Kind.glucose: return 'เครื่องวัดน้ำตาล';
      case _Kind.scale: return 'เครื่องชั่งน้ำหนัก';
      case _Kind.unknown: return s.device.platformName.isNotEmpty ? s.device.platformName : s.device.remoteId.str;
    }
  }

  String _subtitle(DeviceSession s) {
    final p = s.device.platformName.trim();
    return p.isNotEmpty ? p : s.device.remoteId.str;
  }
}

enum _Kind { bp, spo2, temp, glucose, scale, unknown }
