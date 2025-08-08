import 'package:flutter/material.dart';

class LoginQrCamPage extends StatelessWidget {
  const LoginQrCamPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ตัวอย่าง UI สำหรับสแกน QR (ยังไม่เชื่อมต่อกล้องจริง)
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            const Text(
              'กรุณานำกล้องไปส่อง QR Code',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: เชื่อมต่อกล้องจริง หรือกลับหน้าก่อนหน้า
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('กลับ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}