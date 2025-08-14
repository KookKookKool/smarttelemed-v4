import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({Key? key}) : super(key: key);

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  int _elapsed = 0; // เวลาที่ผ่านไป (วินาที)
  Timer? _timer;
  Timer? _navTimer; // <-- ตัวจับเวลาสำหรับนำทางไป /videocall

  String _mmss(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}.${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    // นับเวลาเดินหน้า
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsed++);
    });

    // ครบ 10 วินาที -> ไปหน้า /videocall
    _navTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      Navigator.pushNamed(context, '/videocall'); 
      // ถ้าไม่ต้องการให้ย้อนกลับหน้ารอ: ใช้ pushReplacementNamed(context, '/videocall');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00B3A8);
    const deepBlue = Color(0xFF232A5C);
    const rose = Color(0xFFE11D48);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'พบแพทย์',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFFFFA), Color(0xFFF8FFFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(teal),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ระยะเวลารอ ${_mmss(_elapsed)} นาที',
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'รอพบแพทย์',
              style: TextStyle(
                fontSize: 16,
                color: deepBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            const Text('นัดวันที่ 11 สิงหาคม 2568',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text('เวลา 08.00น.  -  08.30น.',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
                children: [
                  TextSpan(text: 'รายการนัด '),
                  TextSpan(
                    text: 'ฟังผลเลือด',
                    style: TextStyle(color: rose, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }
}
