import 'package:flutter/material.dart';
import 'dart:async';

class IdCardLoader extends StatefulWidget {
  const IdCardLoader({Key? key}) : super(key: key);

  @override
  State<IdCardLoader> createState() => _IdCardLoaderState();
}
class _IdCardLoaderState extends State<IdCardLoader> {
  @override
  void initState() {
    super.initState();
    // หน่วงเวลา 3 วินาที แล้วไปหน้า dashboardscreen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ปุ่ม Back
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 10),

            // โลโก้ esm
            Image.asset(
              'assets/logo.png', // เพิ่มโลโก้ของคุณใน assets
              height: 50,
            ),
            const SizedBox(height: 16),

            // ข้อความ
            const Text(
              'กรุณาเสียบบัตรประชาชน\nเพื่อเข้าสู่ระบบ อสม.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.brown,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // loading indicator
            const SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),

            // ช่องอ่านบัตร
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),

            // บัตรประชาชน (หมุน 90 องศา)
            Transform.rotate(
              angle: -90 * 3.1415926535 / 180, // หมุนเป็นเรเดียน
              child: Image.asset(
                'assets/card.png', // เพิ่มภาพบัตรใน assets
                height: 150,
              ),
            ),
            const Spacer(),

            // ข้อความด้านล่าง
            const Text(
              'ไม่มีบัตรประชาชน',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
