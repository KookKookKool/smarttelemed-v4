// lib/screens/main_pt/widgets/main_slider/calendar_panel.dart
import 'package:flutter/material.dart';
import 'static_calendar.dart';

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({Key? key}) : super(key: key);

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  late final PageController _page = PageController(initialPage: 1);
  int _active = 1;
  final DateTime _base = DateTime(2025, 1, 1);

  DateTime _monthAt(int pageIndex) {
    final offset = pageIndex - 1;
    return DateTime(_base.year, _base.month + offset, 1);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFEFFAF5), borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ปฏิทิน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: AspectRatio(
              aspectRatio: 1 / 1.20,
              child: PageView.builder(
                controller: _page,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _active = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, i) {
                  final dt = _monthAt(i);
                  final isJan2025 = (dt.year == 2025 && dt.month == 1);
                  return StaticCalendar(
                    year: dt.year,
                    month: dt.month,
                    markedDays: isJan2025 ? const [6, 18] : const [],
                    selectedDay: isJan2025 ? 29 : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          DotsIndicator(activeIndex: _active, count: 3),
        ],
      ),
    );
  }
}
