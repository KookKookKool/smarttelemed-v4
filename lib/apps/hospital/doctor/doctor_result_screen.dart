// lib/core/doctor/doctor_result_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';

class DoctorResultScreen extends StatelessWidget {
  const DoctorResultScreen({Key? key}) : super(key: key);

  // ---- style helpers
  static const _deepText = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _teal = Color(0xFF00B3A8);
  static const _cardRadius = 16.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _deepText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'พบแพทย์',
          style: TextStyle(color: _deepText, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEFFFFA), Colors.white],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ───────── การ์ดข้อมูลผู้ป่วย
              _card(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/profile.jpg',
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 72,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.person, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('นายสมใจ อิ่มบุญ',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          _Line('วันเกิด 01 ม.ค. 2500 (อายุ 66 ปี)'),
                          _Line('กรุ๊ปเลือด โอ+'),
                          _Line('น้ำหนัก 70 กก. ส่วนสูง 175 ซม.'),
                          _Line('โรคประจำตัว'),
                          _Line('ประวัติการแพ้'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),

              // ───────── ค่า Vital ล่าสุด
              _sectionHeader('สรุปค่าสัญญาณชีพ'),
              _card(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'วันที่ 11 สิงหาคม 2568 เวลา 16.40 น.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // แถวแรก
                    Row(
                      children: const [
                        Expanded(
                          child: _VitalTile(
                            title: 'BP',
                            value: '140/90',
                            sub: '(65)',
                            valueColor: Colors.deepOrange,
                            unit: 'mmHg',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _VitalTile(
                            title: 'PR',
                            value: '78',
                            unit: 'bpm',
                            valueColor: _teal,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _VitalTile(
                            title: 'RR',
                            value: '20',
                            unit: 'bpm',
                            valueColor: _teal,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _VitalTile(
                            title: 'SpO₂',
                            value: '89',
                            unit: '%',
                            valueColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // แถวสอง
                    Row(
                      children: const [
                        Expanded(
                          child: _VitalTile(
                            title: 'BT',
                            value: '36.7',
                            unit: '°C',
                            valueColor: _teal,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _VitalTile(
                            title: 'DTX',
                            value: '130',
                            unit: 'mg%',
                            valueColor: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(child: _VitalMini(title: 'BW', value: '75 Kg')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _VitalMini(title: 'BMI', value: '20 (Normal)')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),

              // ───────── บันทึกการพบแพทย์
              _sectionHeader('บันทึกการพบแพทย์'),
              _card(
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Lorem ipsum dolor sit amet consectetur. Eget purus neque velit fells '
                  'maecenas suspendisse ultricies et. Eleifend cras vel urna netus fermentum '
                  'in. Facilisis sed odio et sit integer elementum. Cras a ac dui tortor. '
                  'Eu diam convallis vitae arcu massa turpis. Tristique nec morbi urna '
                  'vivamus condimentum et. Nulla aenean parturient sagittis ac cursus. '
                  'Aliquam nulla etiam faucibus urna erat fermentum mi.',
                  style: TextStyle(height: 1.45, color: _deepText),
                ),
              ),
              const SizedBox(height: _gap),

              // ───────── บันทึกการสั่งยา
              _sectionHeader('บันทึกการสั่งยา'),
              _card(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _RxLine('PARACETAMOL 20 tab q 4–6 hr.'),
                    _RxLine('Amoxicillin 20 tab 1×1 pc'),
                    _RxLine('PARACETAMOL 20 tab q 4–6 hr.'),
                    _RxLine('Amoxicillin 20 tab 1×1 pc'),
                  ],
                ),
              ),
              const SizedBox(height: _gap),

              // ───────── นัดหมายถัดไป
              _sectionHeader('นัดหมาย'),
              _appointCard(),
              const SizedBox(height: _gap),

              // ───────── ไฟล์เอกสาร
              _sectionHeader('ไฟล์เอกสาร'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _fileBox('ผลแล็บ.pdf'),
                  const SizedBox(width: 12),
                  _fileBox('ใบรับรองแพทย์.pdf'),
                  const SizedBox(width: 12),
                  _fileAddBox(),
                ],
              ),
              const SizedBox(height: _gap),

              // ───────── QR code
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.qr_code_2_rounded, size: 150),
                ),
              ),
              const SizedBox(height: _gap),

              // ───────── ปุ่มเสร็จสิ้น
              Center(
                child: SizedBox(
                  width: 200,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/mainpt'),
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      backgroundColor: _teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'เสร็จสิ้น',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }

  // ===== Reusable pieces =====
  static Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: _deepText,
          ),
        ),
      );

  static Widget _card({required Widget child, EdgeInsets? padding}) => Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  static Widget _appointCard() {
    const primary = _teal;
    return _card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // วันที่
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFEFFFFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('11',
                      style: TextStyle(
                          fontSize: 24, color: primary, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('ส.ค.',
                      style: TextStyle(
                          fontSize: 22, color: primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('นัดวันที่ 11 สิงหาคม 2568',
                    style: TextStyle(
                        color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('เวลา 08.00 น.  -  08.30 น.',
                    style: TextStyle(color: _deepText)),
                SizedBox(height: 4),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'รายการนัด '),
                    TextSpan(
                        text: 'ฟังผลเลือด',
                        style: TextStyle(
                            color: Color(0xFFE11D48),
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fileBox(String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined,
                size: 28, color: Colors.black45),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ),
        ],
      );

  static Widget _fileAddBox() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, size: 28, color: Colors.black45),
          ),
          const SizedBox(height: 6),
          const SizedBox(width: 96, child: Text('')),
        ],
      );
}

class _VitalTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color valueColor;
  final String? sub;

  const _VitalTile({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    this.valueColor = DoctorResultScreen._teal,
    this.sub,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoctorResultScreen._card(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.black54)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: valueColor)),
              if (sub != null) ...[
                const SizedBox(width: 4),
                Text(sub!,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(fontSize: 11, color: Colors.black38)),
        ],
      ),
    );
  }
}

class _VitalMini extends StatelessWidget {
  final String title;
  final String value;
  const _VitalMini({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoctorResultScreen._card(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  const _Line(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: DoctorResultScreen._deepText),
      );
}

class _RxLine extends StatelessWidget {
  final String text;
  const _RxLine(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ', style: TextStyle(fontSize: 16)),
            Expanded(child: Text(text, style: const TextStyle(color: DoctorResultScreen._deepText))),
          ],
        ),
      );
}
