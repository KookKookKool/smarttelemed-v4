import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background_2.dart';
import 'package:smarttelemed_v4/style/app_colors.dart';

class IdCardLoginScreen extends StatelessWidget {
  const IdCardLoginScreen({Key? key}) : super(key: key);

  void _onInsertCard(BuildContext context) {
    // ตัวอย่าง: แสดง dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เสียบบัตรประชาชน'),
        content: const Text(
          'ฟีเจอร์นี้จะเชื่อมต่อกับเครื่องอ่านบัตรประชาชนในอนาคต',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CircleBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'เข้าสู่ระบบ',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // โลโก้กลาง
                  Image.asset('assets/logo.png', height: 80),
                  const SizedBox(height: 24),
                  // หัวข้อ
                  const Text(
                    'เข้าสู่ระบบการใช้งาน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // กรอกเลขบัตรประชาชน
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'เลขบัตรประชาชน',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: const Icon(
                          Icons.credit_card,
                          color: AppColors.gradientStart,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 13,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // กรอกวันเดือนปีเกิด
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'วันเดือนปีเกิด',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: const Icon(
                          Icons.cake,
                          color: AppColors.gradientEnd,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ปุ่มยืนยัน
                  SizedBox(
                    width: 180,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gradientStart.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // ปุ่มเสียบบัตรประชาชน
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/idcardinsert');
                    },
                    child: Text(
                      'เสียบบัตรประชาชน',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
