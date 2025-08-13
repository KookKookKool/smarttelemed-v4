import 'package:flutter/material.dart';

class IdCardInsertScreen extends StatelessWidget {
  const IdCardInsertScreen({Key? key}) : super(key: key);

  @override
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

            // ลูกศรชี้ขึ้น
            const Icon(
              Icons.arrow_upward,
              size: 50,
              color: Colors.green,
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

            // ปุ่มสำเร็จ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/idcardloader');
                  },
                  child: const Text(
                    'สำเร็จ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

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
