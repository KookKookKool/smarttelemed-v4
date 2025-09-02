import 'package:flutter/material.dart';

import 'package:smarttelemed_v4/shared/widgets/chang_appoint.dart';

class AppointTableScreen extends StatefulWidget {
  const AppointTableScreen({Key? key}) : super(key: key);

  @override
  State<AppointTableScreen> createState() => _AppointTableScreenState();
}

class _AppointTableScreenState extends State<AppointTableScreen> {
  // ข้อมูลตัวอย่าง
  final List<Map<String, String>> _rows = List.generate(16, (i) {
    final date = i == 0 ? '09/08/68' : '13/08/68';
    return {
      'date': date,
      'name': 'นายสมชาย อดวงใจ',
      'age': '68',
      'type': i == 2 ? 'เยี่ยมบ้านประจำไตรมาส' : 'เยี่ยมบ้านประจำเดือน',
    };
  });

  late List<bool> _selected = List<bool>.filled(16, false);
  bool _selectAll = false;

  void _toggleAll(bool? val) {
    final v = val ?? false;
    setState(() {
      _selectAll = v;
      _selected = List<bool>.filled(_selected.length, v);
    });
  }

  void _toggleOne(int index, bool? val) {
    setState(() {
      _selected[index] = val ?? false;
      _selectAll = _selected.every((e) => e);
    });
  }

  int get _selectedCount => _selected.where((e) => e).length;

  @override
  Widget build(BuildContext context) {
    // จำกัดการขยายฟอนต์จากระบบเล็กน้อย เพื่อกันล้น/บีบ
    final mq = MediaQuery.of(context);
    final clampedScaler = mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.15);

    const headerStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87);
    const faintStyle  = TextStyle(fontSize: 14, color: Colors.black54);

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('รายชื่อมีนัดเยี่ยมบ้าน',
              style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // หัวตาราง
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: const [
                    _HeaderCheckbox(),
                    SizedBox(width: 4),
                    _HeadCell('วันที่นัด', flex: 2),
                    _HeadCell('ชื่อ-นามสกุล', flex: 4),
                    _HeadCell('อายุ', flex: 1),
                    _HeadCell('ประเภทนัด', flex: 4),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

              // รายการแถว
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final r = _rows[i];
                    final selected = _selected[i];

                    return Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Checkbox(
                            value: selected,
                            onChanged: (v) => _toggleOne(i, v),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // วันที่
                        Expanded(
                          flex: 2,
                          child: Text(
                            r['date']!,
                            style: faintStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        // ชื่อ
                        Expanded(
                          flex: 4,
                          child: Text(
                            r['name']!,
                            style: faintStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        // อายุ
                        const Expanded(
                          flex: 1,
                          child: Text(
                            '68',
                            textAlign: TextAlign.left,
                            style: faintStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        // ประเภทนัด
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r['type']!,
                                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ปุ่มเลื่อนนัด
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedCount > 0 ? () async {
                      final res = await showChangeAppointDialog(
                        context,
                        selectedCount: _selectedCount,
                        initialDate: DateTime.now(),
                      );
                      if (res != null && mounted) {
                        // TODO: ส่งค่าขึ้น API / อัปเดตรายการในตาราง
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เลื่อนไป ${res.date.day}/${res.date.month}/${res.date.year + 543} : ${res.reason}')),
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedCount > 0 ? const Color(0xFFF8B26A) : Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      shadowColor: Colors.black.withOpacity(0.15),
                    ),
                    child: const Text('เลื่อนนัด', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== ส่วนหัวคอลัมน์ (ช่วยให้โค้ดสั้นลง โดยยังคุม overflow) =====

class _HeadCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeadCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

class _HeaderCheckbox extends StatelessWidget {
  const _HeaderCheckbox();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppointTableScreenState>()!;
    return SizedBox(
      width: 28,
      child: Checkbox(
        value: state._selectAll,
        onChanged: state._toggleAll,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}