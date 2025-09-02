import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ไม่มีการเปลี่ยนหน้าอัตโนมัติ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SvgPicture.asset(
            'assets/logo.svg',
            width: (160),
            height: (160),
            fit: BoxFit.contain,
          ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
