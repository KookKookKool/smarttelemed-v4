import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/themes/background.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';
import 'dart:math';
import 'package:smarttelemed_v4/shared/widgets/time/th_time_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Manubar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 0) {
              // หน้าเดิม
            } else if (index == 1) {
              Navigator.pushNamed(context, '/addcardpt');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/settings');
            }
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ส่วนหัวโปรไฟล์
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: const CircleAvatar(
                        radius: 30,
                        // backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hello !",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Mr.Jimmy S.",
                          style: TextStyle(fontSize: 16),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "อาสาสมัคร",
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ),
                        const Text(
                          "#12345",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // การ์ดแดชบอร์ด
              DashboardCard(),

              const SizedBox(height: 16),

              // ปุ่ม รายชื่อ
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/appointtable'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.description, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "รายชื่อมีนัดเยี่ยมบ้าน",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// DashboardCard และ LegendItem ใหม่
class DashboardCard extends StatefulWidget {
  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  int? selectedIndex;
  final List<_DashboardStat> stats = [
    _DashboardStat(
      color: Colors.green,
      label: "จำนวนที่คนไปเยี่ยมบ้านแล้ว (มีนัดวันนี้)",
      value: 15,
    ),
    _DashboardStat(
      color: Colors.blue,
      label: "จำนวนที่คนไปเยี่ยมบ้านแล้ว (ไม่นัดวันนี้)",
      value: 4,
    ),
    _DashboardStat(
      color: Colors.grey,
      label: "จำนวนที่ยังไม่ได้เยี่ยมบ้าน",
      value: 11,
    ),
  ];

  int get total => stats.fold(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "แดชบอร์ด",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Donut chart
          SizedBox(
            height: 150,
            width: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final local = box.globalToLocal(details.globalPosition);
                      final dx = local.dx - constraints.maxWidth / 2;
                      final dy = local.dy - constraints.maxHeight / 2;
                      final r = sqrt(dx * dx + dy * dy);
                      if (r < 45 || r > 75) return; // tap นอกวง donut
                      double angle = atan2(dy, dx) * 180 / pi;
                      angle = (angle + 360 + 90) % 360; // shift start to top
                      double start = 0;
                      for (int i = 0; i < stats.length; i++) {
                        final sweep = 360 * (stats[i].value / total);
                        if (angle >= start && angle < start + sweep) {
                          setState(() {
                            if (selectedIndex == i) {
                              selectedIndex = null;
                            } else {
                              selectedIndex = i;
                            }
                          });
                          break;
                        }
                        start += sweep;
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      stats: stats,
                      selectedIndex: selectedIndex,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "จำนวน\nผู้ใช้บริการวันนี้",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            selectedIndex != null
                                ? "${stats[selectedIndex!].value}"
                                : "$total",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedIndex != null ? "/${total}" : "/${total}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...List.generate(
            stats.length,
            (i) => GestureDetector(
              onTap: () =>
                  setState(() => selectedIndex = selectedIndex == i ? null : i),
              child: _LegendItem(
                color: stats[i].color,
                text: stats[i].label,
                value: "${stats[i].value} ราย",
                selected: selectedIndex == i,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStat {
  final Color color;
  final String label;
  final int value;
  _DashboardStat({
    required this.color,
    required this.label,
    required this.value,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_DashboardStat> stats;
  final int? selectedIndex;
  _DonutChartPainter({required this.stats, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // ลบตัวแปร rect ที่ไม่ได้ใช้
    final total = stats.fold(0, (sum, s) => sum + s.value);
    double start = -90.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    for (int i = 0; i < stats.length; i++) {
      final sweep = 360 * (stats[i].value / total);
      paint.color = (selectedIndex == null || selectedIndex == i)
          ? stats[i].color
          : stats[i].color.withOpacity(0.3);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - 12,
        ),
        start * 3.1415926535 / 180,
        sweep * 3.1415926535 / 180,
        false,
        paint,
      );
      start += sweep;
    }
    // วาดวงกลมตรงกลาง
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 36,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final String value;
  final bool selected;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.text,
    required this.value,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: selected
          ? BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? color : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
