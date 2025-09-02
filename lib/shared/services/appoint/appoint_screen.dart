// lib/shared/services/appoint/appoint_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';

class AppointScreen extends StatelessWidget {
  const AppointScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // สีหลักที่ใช้ในหน้า
    const green = Color(0xFF22C55E);
    const teal = Color(0xFF14B8A6);
    const blue = Color(0xFF2563EB);
    const rose = Color(0xFFE11D48);

    // ---- helper แบบฟังก์ชัน (ไม่สร้างคลาสเพิ่ม) ----
    Widget gradientText(String t, {double size = 28, FontWeight w = FontWeight.w800}) {
      return ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF22D3EE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r),
        blendMode: BlendMode.srcIn,
        child: Text(t, style: TextStyle(fontSize: size, fontWeight: w)),
      );
    }

    Widget apptCard({
      required String day,
      required String monthShort,
      required String fullDate,
      required String timeRange,
      required String topic,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // บล็อกวันที่ทางซ้าย
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  gradientText(day, size: 36),
                  const SizedBox(height: 4),
                  gradientText(monthShort, size: 28, w: FontWeight.w900),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // รายละเอียดนัด
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('นัดวันที่ $fullDate',
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: blue)),
                  const SizedBox(height: 6),
                  Text('เวลา $timeRange',
                      style: const TextStyle(
                          fontSize: 14.5, color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14.5, color: Color(0xFF374151)),
                      children: const [
                        TextSpan(text: 'รายการนัด '),
                        TextSpan(text: 'ฟังผลเลือด', style: TextStyle(color: rose, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // ---- end helpers ----

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('นัดหมาย',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            )),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFFFFA), Color(0xFFF8FFFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ตัวอย่างการ์ด 4 รายการ (เหมือนภาพ)
            apptCard(
              day: '11',
              monthShort: 'ส.ค.',
              fullDate: '11 สิงหาคม 2568',
              timeRange: '08.00น. - 08.30น.',
              topic: 'ฟังผลเลือด',
            ),
            apptCard(
              day: '11',
              monthShort: 'ส.ค.',
              fullDate: '11 สิงหาคม 2568',
              timeRange: '08.00น. - 08.30น.',
              topic: 'ฟังผลเลือด',
            ),
            apptCard(
              day: '11',
              monthShort: 'ส.ค.',
              fullDate: '11 สิงหาคม 2568',
              timeRange: '08.00น. - 08.30น.',
              topic: 'ฟังผลเลือด',
            ),
            apptCard(
              day: '11',
              monthShort: 'ส.ค.',
              fullDate: '11 สิงหาคม 2568',
              timeRange: '08.00น. - 08.30น.',
              topic: 'ฟังผลเลือด',
            ),
          ],
        ),
      ),
      // ใช้ manubar.dart
      bottomNavigationBar: const Manubar(currentIndex: 1), // ถ้า widget ของคุณต้องการพารามิเตอร์ ให้แก้ไขตามจริง
    );
  }
}
