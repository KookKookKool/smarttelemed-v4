import 'package:flutter/material.dart';

class AppColors {
  static const Color gradientStart = Color(0xFF24E29E); // สีบน
  static const Color gradientEnd = Color(0xFF14C9EA); // สีล่าง
  static const Color primaryColor = Color(0xFF24E29E); // สีหลัก
  static const Color secondaryColor = Color(0xFF14C9EA); // สีรอง
  static const Color textColor = Color(0xFF333333); // สีข้อความ
  static const Color backgroundColor = Color(0xFFF5F5F5); // สีพื้นหลัง
  static const Color buttonColor = Color(0xFF24E29E); // สีปุ่ม
  static const Color buttonTextColor = Colors.white; // สีข้อความ
  static const Color borderColor = Color(0xFFCCCCCC); // สีขอบ

  // Main gradient used in the app
  static const List<Color> btn1 = [
    gradientStart,
    gradientEnd,
  ]; // สีบนสำหรับ gradient 2

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
}
