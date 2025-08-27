// lib/screens/main_pt/main_pt_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

// ส่วนหัว/การ์ดผู้ป่วย
import 'package:smarttelemed_v4/pt/widgets/header_hospital.dart';
import 'package:smarttelemed_v4/pt/widgets/patient_card.dart';

// สไลด์ 4 หน้า
import 'package:smarttelemed_v4/pt/widgets/main_slider/main_slider.dart';

// ปุ่มลัด
import 'package:smarttelemed_v4/pt/widgets/quick_actions_row.dart';

class MainPtScreen extends StatelessWidget {
  const MainPtScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double contentWidth = 360;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const Manubar(currentIndex: 2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFE8FFF7), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: contentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeaderHospital(),
                    SizedBox(height: 14),
                    PatientCard(),
                    SizedBox(height: 12),
                    SizedBox(height: 16),
                    MainSlider(),
                    SizedBox(height: 20),
                    QuickActionsRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
