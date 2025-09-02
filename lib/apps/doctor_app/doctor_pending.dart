import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';

class DoctorPendingScreen extends StatefulWidget {
  const DoctorPendingScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPendingScreen> createState() => _DoctorPendingScreenState();
}

class _DoctorPendingScreenState extends State<DoctorPendingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // รอ 5 วินาทีแล้วไปหน้าผลตรวจ
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/doctorResult');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00B3A8);
    const deepBlue = Color(0xFF232A5C);

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
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEFFFFA), Color(0xFFF8FFFE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // ✅ แก้สีให้ถูกต้อง
            colors: [Color(0xFFEFFFFA), Color(0xFFFDFEFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Column(
          children: [
            SizedBox(height: 36),
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation(teal),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'ระยะเวลารอ 01.34 นาที',
              style: TextStyle(
                fontSize: 14.5,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 48),
            Text(
              'รอผลตรวจ',
              style: TextStyle(
                fontSize: 18,
                color: deepBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'วันที่ 11 สิงหาคม 2568',
              style: TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
            ),
            SizedBox(height: 8),
            Text(
              'รายการนัด  ฟังผลเลือด',
              style: TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
            ),
            SizedBox(height: 18),
            Text(
              'ใช้เวลาพบแพทย์ทั้งหมด\n15.45 นาที',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }
}
