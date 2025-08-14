import 'package:flutter/material.dart';

/// ผลลัพธ์จากป็อปอัปเลื่อนนัด
class ChangeAppointResult {
  final DateTime date;
  final String reason;
  ChangeAppointResult({required this.date, required this.reason});
}

/// เรียกป็อปอัปเลื่อนนัด
Future<ChangeAppointResult?> showChangeAppointDialog(
  BuildContext context, {
  required int selectedCount,
  DateTime? initialDate,
}) {
  return showDialog<ChangeAppointResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ChangeAppointDialog(
      selectedCount: selectedCount,
      initialDate: initialDate ?? DateTime.now(),
    ),
  );
}

class _ChangeAppointDialog extends StatefulWidget {
  final int selectedCount;
  final DateTime initialDate;
  const _ChangeAppointDialog({
    Key? key,
    required this.selectedCount,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<_ChangeAppointDialog> createState() => _ChangeAppointDialogState();
}

class _ChangeAppointDialogState extends State<_ChangeAppointDialog> {
  late DateTime _date = widget.initialDate;
  String _reason = 'เข้าเยี่ยมไม่ทัน';
  final _reasons = const ['เข้าเยี่ยมไม่ทัน', 'ไม่พบคนไข้', 'เหตุผลอื่น ๆ'];

  String _formatThai(DateTime d) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    const weekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.']; // จันทร์=1
    final buddhistYear = d.year + 543;
    final wd = weekdays[(d.weekday - 1) % 7];
    return 'วัน$wdที่ ${d.day} ${months[d.month - 1]} $buddhistYear';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'เลือกวันที่เลื่อนนัด',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            // หัวเรื่อง + ไอคอน
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.event_available_rounded, color: Color(0xFFFFB74D)),
                SizedBox(width: 8),
                Text('เลื่อนนัด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'จำนวนที่เลือก ${widget.selectedCount} รายชื่อ',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 18),

            // เลื่อนไปวันที่
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('เลื่อนไปวันที่',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: _formatHint(_dummyNowForHint()),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: const Icon(Icons.calendar_today_rounded,
                        color: Colors.black38),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  controller:
                      TextEditingController(text: _formatThai(_date)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // สาเหตุ
            const Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('สาเหตุ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _reason,
              items: _reasons
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v ?? _reason),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  ChangeAppointResult(date: _date, reason: _reason),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8B26A),
                  foregroundColor: Colors.black87,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('เลื่อนนัด',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ใช้เพื่อโชว์ hint ตัวอย่างในดีไซน์
  static DateTime _dummyNowForHint() => DateTime(2025, 8, 23);
  static String _formatHint(DateTime d) {
    const m = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    const wd = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    return 'วัน${wd[(d.weekday - 1) % 7]}ที่ ${d.day} ${m[d.month - 1]} ${d.year + 543}';
  }
}
