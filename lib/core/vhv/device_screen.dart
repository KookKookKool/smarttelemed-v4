import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return CircleBackground(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Title (จัดกลาง)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 180,
                      height: 180,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'สวัสดี !',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'โรงพยาบาลอีเอสเอ็ม',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'E.S.M. Solution',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add your actions here
                    },
                    child: const Text('เชื่อมต่ออุปกรณ์'),
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(274, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _navigateTo(context, '/idcardlog');
                    },
                    child: const Text('เข้าสู่ระบบใช้งาน'),
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(274, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
