import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/services/device/video/device_video_page.dart';

class DevicesMenuSection extends StatelessWidget {
  const DevicesMenuSection({super.key, this.title = 'Devices'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        kind: DeviceKind.bp,
        title: 'เครื่องวัดความดัน',
        subtitle: 'Yuwell YE860A',
        thumb: 'assets/devices/bp.jpg',
      ),
      _MenuItem(
        kind: DeviceKind.spo2,
        title: 'เครื่องวัดออกซิเจนปลายนิ้ว',
        subtitle: 'Jumper JPD-500',
        thumb: 'assets/devices/spo2.jpg',
      ),
      _MenuItem(
        kind: DeviceKind.temp,
        title: 'เครื่องวัดอุณหภูมิ',
        subtitle: 'Beurer FT95',
        thumb: 'assets/devices/thermo.jpg',
      ),
      _MenuItem(
        kind: DeviceKind.glucose,
        title: 'เครื่องวัดน้ำตาล',
        subtitle: 'Accu-Chek Active',
        thumb: 'assets/devices/glucose.jpg',
      ),
      _MenuItem(
        kind: DeviceKind.scale,
        title: 'เครื่องชั่งน้ำหนัก',
        subtitle: 'Mi Body Scale 2',
        thumb: 'assets/devices/scale.png',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('(${items.length})', style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ]),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _MenuCard(item: items[i]),
        ),
      ],
    );
  }
}

class _MenuItem {
  final DeviceKind kind;
  final String title;
  final String subtitle;
  final String thumb;
  const _MenuItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.thumb,
  });
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final _MenuItem item;

  static const double _cardRadius = 18;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DeviceVideoPage(kind: item.kind, titleHint: item.title, modelHint: item.subtitle)),
          );
        },
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
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth;
                final double thumb = (w.clamp(280.0, 480.0)) / 4.5;
                final double gap = w < 360 ? 12 : 18;

                return Row(
                  children: [
                    _thumb(item.thumb, thumb),
                    SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(item.subtitle,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.2)),
                        ],
                      ),
                    ),
                    SizedBox(width: gap),
                  ],
                );
              }),
            ),
            const Positioned(
              top: 18, right: 18,
              child: Icon(Icons.chevron_right, size: 32, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(String asset, double size) {
    final fallback = Container(
      width: size, height: size,
      decoration: BoxDecoration(color: const Color(0xFFF3F6F8), borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.devices_other, size: 36, color: Colors.black38),
    );
    return SizedBox(
      width: size, height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }
}
