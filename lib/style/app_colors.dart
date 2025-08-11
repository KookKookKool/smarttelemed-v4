import 'package:flutter/material.dart';

class AppColors {
  static const Color gradientStart = Color(0xFF24E29E); // สีบน
  static const Color gradientEnd = Color(0xFF14C9EA); // สีล่าง

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
}
