// lib/screens/main_pt/widgets/main_slider/static_calendar.dart
import 'package:flutter/material.dart';

class StaticCalendar extends StatelessWidget {
  final int year;
  final int month;
  final List<int> markedDays;
  final int? selectedDay;
  const StaticCalendar({
    Key? key,
    required this.year,
    required this.month,
    this.markedDays = const [],
    this.selectedDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final offset = firstDay.weekday % 7; // Sun=0
    final daysInMonth = DateTime(year, month + 1, 0).day;

    const weekLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const spacing = 6.0;

    return Column(
      children: [
        Text('${_monthShort(month)} $year', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: Row(
            children: weekLetters
                .map((w) => Expanded(child: Center(child: Text(w, style: const TextStyle(color: Colors.black54)))))
                .toList(),
          ),
        ),
        const SizedBox(height: spacing),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: spacing, crossAxisSpacing: 0, childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, i) {
            final d = i - offset + 1;
            if (d < 1 || d > daysInMonth) return const SizedBox.shrink();
            final isSelected = selectedDay != null && d == selectedDay;
            final isMarked = markedDays.contains(d);

            return LayoutBuilder(
              builder: (_, cellC) {
                final size = cellC.maxWidth;
                final dayCircle = size * 0.58;
                final dot = size * 0.12;
                final font = size * 0.32;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: dayCircle, height: dayCircle,
                        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                      ),
                    Text('$d',
                        style: TextStyle(
                          fontSize: font, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        )),
                    if (!isSelected && isMarked)
                      Positioned(
                        bottom: size * 0.10,
                        child: Container(
                          width: dot, height: dot,
                          decoration: const BoxDecoration(color: Color(0xFFFFC400), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _monthShort(int m) {
    const full = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return full[m];
  }
}

class DotsIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;
  const DotsIndicator({Key? key, required this.activeIndex, required this.count}) : super(key: key);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (i) {
            final active = i == activeIndex;
            return Container(
              width: active ? 10 : 6, height: active ? 10 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFBDBDBD) : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      );
}
