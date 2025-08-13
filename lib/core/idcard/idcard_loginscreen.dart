import 'package:flutter/material.dart';

class IdCardLoginScreen extends StatelessWidget {
  const IdCardLoginScreen({Key? key}) : super(key: key);

  void _onInsertCard(BuildContext context) {
    // ตัวอย่าง: แสดง dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เสียบบัตรประชาชน'),
        content: const Text('ฟีเจอร์นี้จะเชื่อมต่อกับเครื่องอ่านบัตรประชาชนในอนาคต'),
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
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar พร้อมปุ่มย้อนกลับ
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เข้าสู่ระบบ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // โลโก้
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 20),

                  // หัวข้อ
                  const Text(
                    'เข้าสู่ระบบการใช้งาน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // กรอกเลขบัตรประชาชน
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'เลขบัตรประชาชน',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 13,
                  ),
                  const SizedBox(height: 20),

                  // กรอกวันเดือนปีเกิด
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'วันเดือนปีเกิด (เช่น 01011990)',
                      prefixIcon: const Icon(Icons.cake),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 30),

                  // ปุ่มยืนยัน
                  ElevatedButton(
                    onPressed: () {
                      // TODO: handle login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'ยืนยัน',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ปุ่มเสียบบัตรประชาชน
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/idcardinsert');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.deepPurple, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.contact_mail, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            'เสียบบัตรประชาชน',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
