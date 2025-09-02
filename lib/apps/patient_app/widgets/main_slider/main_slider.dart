// lib/screens/main_pt/widgets/main_slider/main_slider.dart
import 'package:flutter/material.dart';
import 'calendar_panel.dart';
import 'vital_history_table.dart';
import 'doctor_visit_history.dart';
import 'home_visit_history.dart';

class MainSlider extends StatefulWidget {
  const MainSlider({Key? key}) : super(key: key);

  @override
  State<MainSlider> createState() => _MainSliderState();
}

class _MainSliderState extends State<MainSlider> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double sliderHeight = 450;

    Widget dot(int i) {
      final active = _index == i;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: active ? 18 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00B3A8) : const Color(0xFFD5DDE1),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    final tabs = const [
      (Icons.calendar_month_rounded, 'วัน/เดือนนัดหมาย'),
      (Icons.monitor_heart_rounded, 'ค่าสัญญาณชีพ'),
      (Icons.assignment_ind_rounded, 'ประวัติพบแพทย์'),
      (Icons.home_rounded, 'ประวัติเยี่ยมบ้าน'),
    ];

    Widget topTabs() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == _index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _controller.animateToPage(i,
                      duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE6FBF8) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: selected ? const Color(0xFF00B3A8) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Icon(tabs[i].$1, size: 18, color: selected ? const Color(0xFF00B3A8) : Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          tabs[i].$2,
                          style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600,
                            color: selected ? const Color(0xFF00B3A8) : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        topTabs(),
        const SizedBox(height: 12),
        SizedBox(
          height: sliderHeight,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: const [
              SingleChildScrollView(child: CalendarPanel()),
              SingleChildScrollView(child: VitalHistoryTable()),
              SingleChildScrollView(child: DoctorVisitHistory()),
              SingleChildScrollView(child: HomeVisitHistory()),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, dot)),
      ],
    );
  }
}