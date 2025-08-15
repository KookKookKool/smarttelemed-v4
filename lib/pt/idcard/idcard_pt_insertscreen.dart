import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background.dart';
import 'package:smarttelemed_v4/style/app_colors.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class IdCardPtInsertScreen extends StatelessWidget {
  const IdCardPtInsertScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // ปุ่ม Back ซ้ายบน
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: ShaderMask(
                    shaderCallback: (rect) =>
                        AppColors.mainGradient.createShader(rect),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // เนื้อหา
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // โลโก้กลาง
                      Image.asset('assets/logo.png', height: 80),
                      const SizedBox(height: 16),
                      // ข้อความ
                      const Text(
                        'กรุณาเสียบบัตรประชาชน\n ผู้เข้ารับการรักษา',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ลูกศรชี้ขึ้น
                      ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.mainGradient.createShader(rect),
                        child: const Icon(
                          Icons.arrow_upward,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ช่องอ่านบัตร
                      Container(
                        width: 200,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                      // บัตรประชาชน (หมุน 90 องศา)
                      Transform.rotate(
                        angle: 0,
                        child: Image.asset('assets/card.png', height: 250),
                      ),
                      const SizedBox(height: 40),
                      // ปุ่มสำเร็จ
                      SizedBox(
                        width: 114,
                        height: 41,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/idcardptloader');
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
                      const SizedBox(height: 24),
                      // text for no ID card
                      Text(
                        'ไม่มีบัตรประชาชน',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: Manubar()),
            ],
          ),
        ),
      ),
    );
  }
}
