import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';
import 'package:smarttelemed_v4/core/vitalsign/vitalsign_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';


class MainPtScreen extends StatelessWidget {
  const MainPtScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double contentWidth = 360;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const Manubar(currentIndex: 1),
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

                    /// ⬇️ เปลี่ยนจาก _CalendarPanel() เป็นสไลด์ 4 หน้า
                    _MainSlider(),

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
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('โรงพยาบาลอีเอสเอ็ม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('E.S.M Solution Hospital', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}

/// ───────────────── การ์ดผู้ป่วย
class _PatientCard extends StatelessWidget {
  const _PatientCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 6))],
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
              errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 92, height: 72, child: Icon(Icons.person)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('นายสมใจ อิ่มบุญ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('วันเกิด 01 ม.ค. 2500 (อายุ 66 ปี)', style: TextStyle(fontSize: 13)),
                Text('กรุ๊ปเลือด โอ+', style: TextStyle(fontSize: 13)),
                Text('น้ำหนัก 70 กก. ส่วนสูง 175 ซม.', style: TextStyle(fontSize: 13)),
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

/// ───────────────── Main Slider: 4 หน้า (ปฏิทิน / Vital / พบแพทย์ / เยี่ยมบ้าน)
class _MainSlider extends StatefulWidget {
  const _MainSlider({Key? key}) : super(key: key);

  @override
  State<_MainSlider> createState() => _MainSliderState();
}

class _MainSliderState extends State<_MainSlider> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ให้สูงพอเสมอ (หน้าในเลื่อนเองได้ ไม่ล้น)
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
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE6FBF8) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? const Color(0xFF00B3A8) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(tabs[i].$1,
                            size: 18,
                            color: selected ? const Color(0xFF00B3A8) : Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          tabs[i].$2,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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

        // ✅ สูงพอ และให้แต่ละหน้าเลื่อนเองได้
        SizedBox(
          height: sliderHeight,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: const [
              SingleChildScrollView(child: _CalendarPanel()),
              SingleChildScrollView(child: _VitalHistoryTable()),
              SingleChildScrollView(child: _DoctorVisitHistory()),
              SingleChildScrollView(child: _HomeVisitHistory()),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, dot),
        ),
      ],
    );
  }
}
/// ───────────────── แผงปฏิทิน (ภายในสไลด์หน้า 1)
class _CalendarPanel extends StatefulWidget {
  const _CalendarPanel({Key? key}) : super(key: key);

  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
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

              // ⬇️ แทนที่ LayoutBuilder เดิมทั้งหมดด้วย AspectRatio
              child: AspectRatio(
                // อัตราส่วน ~กว้าง:สูง ให้สูงกว่า grid 6 แถวเล็กน้อยเพื่อกันล้น
                aspectRatio: 1 / 1.20, // = กว้าง/สูง (สูง ≈ 1.20*กว้าง)

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
              ),
            ),
          const SizedBox(height: 8),
          _DotsIndicator(activeIndex: _active, count: 3),
        ],
      ),
    );
  }
}

/// ───────────────── ปฏิทิน Static
class _StaticCalendar extends StatelessWidget {
  final int year;
  final int month;
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
                          fontSize: font,
                          fontWeight: FontWeight.w600,
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

/// จุดบอกหน้าเล็ก ๆ ในปฏิทิน
class _DotsIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;
  const _DotsIndicator({Key? key, required this.activeIndex, required this.count}) : super(key: key);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (i) {
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
          },
        ),
      );
}

/// ───────────────── หน้า 2: ตารางประวัติค่าสัญญาณชีพ
class _VitalHistoryTable extends StatelessWidget {
  const _VitalHistoryTable({Key? key}) : super(key: key);

  TableRow _header() => const TableRow(
        decoration: BoxDecoration(color: Color(0xFFF4F6F8)),
        children: [
          _Th('Date\n(DD/MM/YY)'), _Th('BP\n(mmHg)'), _Th('PR\n(bpm)'),
          _Th('RR\n(bpm)'), _Th('SpO2\n(%)'), _Th('BT\n(°C)'),
        ],
      );

  TableRow _data(List<String> cols) =>
      TableRow(decoration: const BoxDecoration(color: Colors.white), children: cols.map((e) => _Td(e)).toList());

  @override
  Widget build(BuildContext context) {
    final rows = <TableRow>[
      _header(),
      _data(const ['11/08/68', '140/90', '76', '20', '100', '36.7']),
      _data(const ['', '', '', '', '', '']),
      _data(const ['', '', '', '', '', '']),
      _data(const ['', '', '', '', '', '']),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('ประวัติค่าสัญญาณชีพ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(.9),
              3: FlexColumnWidth(.9),
              4: FlexColumnWidth(.9),
              5: FlexColumnWidth(1.0),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(text, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)));
}

class _Td extends StatelessWidget {
  final String text;
  const _Td(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: .9)),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
      );
}

/// ───────────────── หน้า 3: ประวัติ “พบแพทย์”
class _DoctorVisitHistory extends StatelessWidget {
  const _DoctorVisitHistory({Key? key}) : super(key: key);

  Widget _item({required String title, required String by}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(by, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF00B3A8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('ประวัติการพบแพทย์', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      _item(title: 'นัดวันที่ 11 สิงหาคม 2568', by: 'พบแพทย์โดย นพ.อนันต์ ใจดี'),
      _item(title: 'นัดวันที่ 01 สิงหาคม 2568', by: 'พบแพทย์โดย นพ.อนันต์ ใจดี'),
    ]);
  }
}

/// ───────────────── หน้า 4: ประวัติ “เยี่ยมบ้าน”
class _HomeVisitHistory extends StatelessWidget {
  const _HomeVisitHistory({Key? key}) : super(key: key);

  Widget _item({required String title, required String by}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(by, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF00B3A8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('ประวัติการเยี่ยมบ้าน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      _item(title: 'นัดวันที่ 11 สิงหาคม 2568', by: 'บันทึกโดย บส.สมใจ ยิ้มดี'),
      _item(title: 'นัดวันที่ 01 สิงหาคม 2568', by: 'บันทึกโดย บส.สมใจ ยิ้มดี'),
      _item(title: 'นัดวันที่ 22 กรกฎาคม 2568', by: 'บันทึกโดย บส.สมใจ ยิ้มดี'),
    ]);
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
        _QuickAction(icon: Icons.medical_services_outlined, label: 'พบแพทย์', routeName: '/doctor'),
        _QuickAction(icon: Icons.calendar_month_outlined, label: 'นัดหมาย', routeName: '/appoint'),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;
  const _QuickAction({Key? key, required this.icon, required this.label, required this.routeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (label == 'ตรวจ') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VitalSignScreen()));
        } else {
          Navigator.pushNamed(context, routeName);
        }
      },
      child: Column(
        children: [
          Container(
            width: 96,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Center(child: Icon(icon, size: 36, color: const Color(0xFF00B3A8))),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
