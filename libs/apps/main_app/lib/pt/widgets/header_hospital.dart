// lib/screens/main_pt/widgets/header_hospital.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeaderHospital extends StatelessWidget {
  const HeaderHospital({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SvgPicture.asset(
            'assets/logo.svg',
            width: 60, height: 60, fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('โรงพยาบาลอีเอสเอ็ม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('E.S.M Solution Hospital', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}