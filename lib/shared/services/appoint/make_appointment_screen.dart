// lib/core/appoint/make_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class MakeAppointmentScreen extends StatefulWidget {
  const MakeAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<MakeAppointmentScreen> createState() => _MakeAppointmentScreenState();
}

class _MakeAppointmentScreenState extends State<MakeAppointmentScreen> {
  DateTime _date = DateTime.now();
  String _timeSlot = '11.00น. - 12.00น.';
  String _type = 'นัดเยี่ยมบ้านประจำเดือน';
  final _detailCtrl = TextEditingController();

  final _timeSlots = const [
    '08.00น. - 09.00น.',
    '09.00น. - 10.00น.',
    '10.00น. - 11.00น.',
    '11.00น. - 12.00น.',
    '13.00น. - 14.00น.',
    '14.00น. - 15.00น.',
  ];

  final _types = const [
    'นัดเยี่ยมบ้านประจำเดือน',
    'นัดเยี่ยมบ้านครั้งแรก',
    'ติดตามอาการ',
  ];

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  String _thaiDate(DateTime d) {
    const wd = ['จันทร์','อังคาร','พุธ','พฤหัสบดี','ศุกร์','เสาร์','อาทิตย์'];
    const ms = ['ม.ค.','ก.พ.','มี.ค.','เม.ย.','พ.ค.','มิ.ย.','ก.ค.','ส.ค.','ก.ย.','ต.ค.','พ.ย.','ธ.ค.'];
    final buddhist = d.year + 543;
    return 'วัน${wd[d.weekday-1]}ที่ ${d.day} ${ms[d.month-1]} $buddhist';
    // ตัวอย่างที่ภาพโชว์ “วันเสาร์ที่ 23 ส.ค. 2568”
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'เลือกวันที่นัด',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null) setState(() => _date = picked);
  }

  InputDecoration _filledDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F6F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00B3A8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ทำนัด',
            style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800)),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF1FFFB), Colors.white],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFFFFA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // วันที่นัด
                const SizedBox(height: 8),
                const _Label('วันที่นัด'),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      readOnly: true,
                      decoration: _filledDecoration(
                        hint: _thaiDate(_date),
                        suffix: const Icon(Icons.calendar_today_rounded, color: Colors.black38),
                      ),
                    ),
                  ),
                ),

                // ช่วงเวลานัด
                const SizedBox(height: 16),
                const _Label('ช่วงเวลานัด'),
                DropdownButtonFormField<String>(
                  value: _timeSlot,
                  items: _timeSlots
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _timeSlot = v ?? _timeSlot),
                  decoration: _filledDecoration(suffix: const Icon(Icons.expand_more)),
                ),

                // ประเภทนัด
                const SizedBox(height: 16),
                const _Label('ประเภทนัด'),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: _types
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                  decoration: _filledDecoration(suffix: const Icon(Icons.expand_more)),
                ),

                // รายละเอียดเพิ่มเติม
                const SizedBox(height: 16),
                const _Label('รายละเอียดเพิ่มเติม'),
                TextField(
                  controller: _detailCtrl,
                  maxLines: 6,
                  decoration: _filledDecoration(),
                ),

                const SizedBox(height: 28),
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: ส่งข้อมูลไป backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('สร้างนัดเรียบร้อย')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 6,
                        shadowColor: Colors.black26,
                        backgroundColor: teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('ทำนัด',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      );
}
