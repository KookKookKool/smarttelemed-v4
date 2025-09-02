import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainPtScreen extends StatelessWidget {
  const MainPtScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double contentWidth = 360; // คุมความกว้างให้ใกล้เคียงดีไซน์

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const Manubar(), // เชื่อม Bar ที่สร้างไว้
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8FFF7), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: contentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _HeaderHospital(),
                    SizedBox(height: 14),
                    _PatientCard(),
                    SizedBox(height: 16),
                    _CalendarPanel(),
                    SizedBox(height: 20),
                    _QuickActionsRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ───────────────── Header: โลโก้ + ชื่อรพ.
class _HeaderHospital extends StatelessWidget {
  const _HeaderHospital({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SvgPicture.asset(
            'assets/logo.svg',
            width: (160),
            height: (160),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.local_hospital),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'โรงพยาบาลอีเอสเอ็ม',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              'E.S.M Solution Hospital',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}

/// ───────────────── การ์ดผู้ป่วย (รูป + รายละเอียดย่อ)
class _PatientCard extends StatelessWidget {
  const _PatientCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/profile.jpg',
              width: 92,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 92,
                height: 72,
                child: Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'นายสมใจ อิ่มบุญ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'วันเกิด 01 ม.ค. 2500 (อายุ 66 ปี)',
                  style: TextStyle(fontSize: 13),
                ),
                Text('กรุ๊ปเลือด โอ+', style: TextStyle(fontSize: 13)),
                Text(
                  'น้ำหนัก 70 กก. ส่วนสูง 175 ซม.',
                  style: TextStyle(fontSize: 13),
                ),
                Text('โรคประจำตัว', style: TextStyle(fontSize: 13)),
                Text('ประวัติการแพ้', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── แผงปฏิทิน (หัวข้อ + ปุ่มแก้ไข + ปฏิทิน)
class _CalendarPanel extends StatefulWidget {
  const _CalendarPanel({Key? key}) : super(key: key);

  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
  // ให้หน้าเริ่มต้นเป็นเดือนกลาง (index = 1)
  late final PageController _page = PageController(initialPage: 1);
  int _active = 1;

  // ตั้งฐานกลางเป็น Jan 2025 ตามภาพ
  final DateTime _base = DateTime(2025, 1, 1);

  DateTime _monthAt(int pageIndex) {
    // page 0 = เดือนก่อนหน้า, page 1 = เดือนฐาน, page 2 = เดือนถัดไป
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
      // พื้นหลังเขียวอ่อนตามภาพ
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // หัวข้อ "ปฏิทิน" + ปุ่มดินสอ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ปฏิทิน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () {
                  // TODO: แก้ไข/ไปหน้าตั้งค่านัด
                },
                icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // การ์ดปฏิทิน
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: LayoutBuilder(
              builder: (context, c) {
                // คำนวณความสูงจากความกว้างจริงของการ์ด
                final w = c.maxWidth; // ความกว้างพื้นที่ในกล่องปฏิทิน
                const rows = 6;
                const spacing = 6.0;
                final cell = w / 7; // ช่องเป็นจัตุรัส => สูงเท่ากว้าง
                final gridH = cell * rows + spacing * (rows - 1);
                // header = เดือน + เว้น + แถวชื่อวัน + เว้น
                const headerH = 16.0 + 8.0 + 18.0 + 6.0;
                final totalH = gridH + headerH;

                return SizedBox(
                  height: totalH, // ✅ พอดีกับคอลัมน์ของ _StaticCalendar
                  child: PageView.builder(
                    controller: _page,
                    itemCount: 3, // ก่อนหน้า / ปัจจุบัน / ถัดไป
                    onPageChanged: (i) => setState(() => _active = i),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, i) {
                      final dt = _monthAt(i);
                      final isJan2025 = (dt.year == 2025 && dt.month == 1);
                      return _StaticCalendar(
                        year: dt.year,
                        month: dt.month,
                        markedDays: isJan2025 ? const [6, 18] : const [],
                        selectedDay: isJan2025 ? 29 : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _DotsIndicator(activeIndex: _active, count: 3),
        ],
      ),
    );
  }
}

/// ปฏิทินแบบ Static ไม่พึ่งแพ็กเกจภายนอก — จัดหน้าให้เหมือนภาพ
class _StaticCalendar extends StatelessWidget {
  final int year;
  final int month; // 1-12
  final List<int> markedDays;
  final int? selectedDay;

  const _StaticCalendar({
    Key? key,
    required this.year,
    required this.month,
    this.markedDays = const [],
    this.selectedDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final firstWeekday = firstDay.weekday; // Mon=1 ... Sun=7
    final offset = firstWeekday % 7; // Sun=0
    final daysInMonth = DateTime(year, month + 1, 0).day;

    const weekLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const spacing = 6.0;

    return Column(
      children: [
        Text(
          '${_monthShort(month)} $year',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // แถวอักษรวัน: กำหนดความสูงคงที่ให้เสถียร
        SizedBox(
          height: 18,
          child: Row(
            children: weekLetters
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: spacing),

        // ตารางวัน 7x6 — ช่องจัตุรัส ป้องกันล้น
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: spacing,
            crossAxisSpacing: 0,
            childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, i) {
            final d = i - offset + 1;
            if (d < 1 || d > daysInMonth) return const SizedBox.shrink();

            final isSelected = (selectedDay != null && d == selectedDay);
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
                        width: dayCircle,
                        height: dayCircle,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      '$d',
                      style: TextStyle(
                        fontSize: font,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (!isSelected && isMarked)
                      Positioned(
                        bottom: size * 0.10,
                        child: Container(
                          width: dot,
                          height: dot,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFC400),
                            shape: BoxShape.circle,
                          ),
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
    const names = [
      '',
      'Dec',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
    ];
    // ถ้าอยากเรียงเริ่ม Jan ให้ใช้ชุดชื่อเดิมได้ ผมยกมาสั้นๆเพื่ออ่านง่าย
    const full = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return full[m];
  }
}

/// จุดบอกหน้า (สามจุดด้านล่างปฏิทิน)
class _DotsIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;
  const _DotsIndicator({
    Key? key,
    required this.activeIndex,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return Container(
          width: active ? 10 : 6,
          height: active ? 10 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFBDBDBD) : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

/// ───────────────── ปุ่มลัด 3 ปุ่ม (ตรวจ / พบแพทย์ / นัดหมาย)
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _QuickAction(icon: Icons.search, label: 'ตรวจ', routeName: '/search'),
        _QuickAction(
          icon: Icons.medical_services_outlined,
          label: 'พบแพทย์',
          routeName: '/doctor',
        ),
        _QuickAction(
          icon: Icons.calendar_month_outlined,
          label: 'นัดหมาย',
          routeName: '/appointment',
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;
  const _QuickAction({
    Key? key,
    required this.icon,
    required this.label,
    required this.routeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: กำหนดปลายทางจริงของแอป
        // Navigator.pushNamed(context, routeName);
      },
      child: Column(
        children: [
          Container(
            width: 96,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 36, color: const Color(0xFF00B3A8)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
