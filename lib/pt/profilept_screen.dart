import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class ProfilePtScreen extends StatelessWidget {
  const ProfilePtScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // กำหนดความกว้างคอนเทนต์ให้ใกล้เคียงภาพ (ดูสวยบนมือถือทุกขนาด)
    const double contentWidth = 360;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const Manubar(currentIndex: 1),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8FFF7),
              Color(0xFFFFFFFF),
            ], // ไล่เฉดอ่อนแบบในภาพ
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: contentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Header โลโก้ + ชื่อรพ. ────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/logo.png', // ← แก้ path ให้ตรงกับโปรเจกต์
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.local_hospital, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'โรงพยาบาลอีเอสเอ็ม',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'E.S.M Solution Hospital',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── รูปโปรไฟล์ ────────────────────────────────────────────
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      // clipBehavior: Clip.antiAlias,
                      // // // child: Image.asset(
                      // // //   // 'assets/profile.jpg', // ← แก้ path ให้ตรงกับโปรเจกต์
                      // //   fit: BoxFit.cover,
                      // //   errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 72),
                      // ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'HN 123456-78',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── ฟิลด์ข้อมูลแบบ pill ───────────────────────────────────
                    const _FieldLabel('ชื่อ–นามสกุล'),
                    const _ReadOnlyPill(value: 'นายสมใจ อิ่มบุญ'),
                    const SizedBox(height: 14),

                    const _FieldLabel('วันเดือนปีเกิด'),
                    const _ReadOnlyPill(value: '01 มกราคม 2500'),
                    const SizedBox(height: 14),

                    const _FieldLabel('เลขบัตรประชาชน'),
                    const _ReadOnlyPill(value: '12100 00123 456'),
                    const SizedBox(height: 14),

                    const _FieldLabel('สิทธิการรักษา'),
                    const _ReadOnlyPill(value: 'โรงพยาบาลหนึ่งสองสาม'),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // TODO: นำทางไปหน้ารายละเอียดทั้งหมด
                        // Navigator.pushNamed(context, '/patient_detail_all');
                      },
                      child: const Text(
                        'ดูข้อมูลทั้งหมด',
                        style: TextStyle(
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── ปุ่ม "ถัดไป" ไล่เฉด ───────────────────────────────────
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: Material(
                        elevation: 8,
                        shadowColor: const Color(0xFF2BB673).withOpacity(0.35),
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D084), Color(0xFF00B3FF)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              // TODO: กำหนดเส้นทางปลายทางตามฟลว์ของคุณ
                              Navigator.pushNamed(context, '/mainpt');
                            },
                            child: const Center(
                              child: Text(
                                'ถัดไป',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
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

// ───────────────────── Helper Widgets ─────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _ReadOnlyPill extends StatelessWidget {
  final String value;
  const _ReadOnlyPill({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    height: 52, // ขนาด pill ให้ใกล้เคียงภาพ
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      value,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      overflow: TextOverflow.ellipsis,
    ),
  );
}
