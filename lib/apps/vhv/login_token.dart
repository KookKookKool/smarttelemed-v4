import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/style/app_colors.dart';
import 'package:smarttelemed_v4/shared/utils/responsive.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_qrcam.dart';
import 'package:smarttelemed_v4/shared/api/backend_api.dart';
import 'package:smarttelemed_v4/storage/storage.dart';

class LoginTokenPage extends StatefulWidget {
  const LoginTokenPage({Key? key}) : super(key: key);

  @override
  State<LoginTokenPage> createState() => _LoginTokenPageState();
}

class _LoginTokenPageState extends State<LoginTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  String? _errorText;

  Map<String, dynamic>? _careUnitData; // เก็บข้อมูลที่ได้จาก API

  Future<void> _onConfirm() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorText = 'กรุณากรอก Token';
      });
      return;
    }
    setState(() {
      _errorText = null;
    });

    // เรียก API และบันทึกข้อมูลลง Hive
    final result = await CareUnitApi.fetchCareUnit(token);
    setState(() {
      _careUnitData = result;
    });
    print('CareUnit API result: $_careUnitData');

    if (result == null) {
      // ไม่มีการตอบกลับจาก API (network error)
      print('Network error - no response from API');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // บันทึกข้อมูลลง Hive ทุกกรณีที่มีการตอบกลับ
    await CareUnitStorage.saveCareUnitData(result);
    await CareUnitStorage.debugHiveContents(); // Debug ข้อมูลใน Hive

    final message = result['message'] ?? '';
    print('API Message: $message');

    if (message == 'success') {
      // สำเร็จ - ไปหน้าถัดไป
      print('✅ บันทึกข้อมูล SUCCESS ลง Hive เรียบร้อย');

      final offlineData = await CareUnitStorage.loadCareUnitData();
      print('Offline data verification: $offlineData');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 พบข้อมูลและบันทึกเรียบร้อย'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushNamed(context, '/device');
    } else {
      // แสดงข้อความ error แต่ยังบันทึกข้อมูลไว้
      String errorMessage = 'ไม่พบข้อมูลสำหรับรหัสที่กรอก';

      if (message == 'not found customer') {
        errorMessage =
            '❌ ไม่พบลูกค้าสำหรับรหัส: $token\n(แต่บันทึกข้อมูลไว้แล้ว)';
      } else if (message == 'not found care unit') {
        errorMessage = '⚠️ พบลูกค้าแต่ไม่มี Care Unit\n(บันทึกข้อมูลไว้แล้ว)';
      } else if (message.isNotEmpty) {
        errorMessage = '📝 เซิร์ฟเวอร์ตอบ: $message\n(บันทึกข้อมูลไว้แล้ว)';
      }

      print('⚠️ บันทึกข้อมูล ERROR CASE ลง Hive: $errorMessage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: ShaderMask(
              shaderCallback: (rect) =>
                  AppColors.mainGradient.createShader(rect),
              child: const Icon(Icons.qr_code, color: Colors.white),
            ),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginQrCamPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;
                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
              if (result != null && result is String) {
                setState(() {
                  _tokenController.text = result;
                });
              }
            },
          ),
        ],
        title: const Text(''),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // โลโก้และชื่อ
                Builder(
                  builder: (ctx) {
                    final r = ResponsiveSizer(ctx);
                    return Column(
                      children: [
                        SvgPicture.asset(
                          'assets/logo.svg',
                          width: r.sw(160),
                          height: r.sw(160),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: r.sh(120)),
                      ],
                    );
                  },
                ),
                // Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                      'Token Hospital',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'ESM123456790',
                      errorText: _errorText,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                // ปุ่มยืนยัน
                Builder(
                  builder: (ctx) {
                    final r = ResponsiveSizer(ctx);
                    return SizedBox(
                      width: r.sw(120),
                      height: r.sh(44),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.mainGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientStart.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'ยืนยัน',
                            style: TextStyle(
                              fontSize: r.sf(14),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // ลิงก์ข้าม API สำหรับกรณีฉุกเฉิน
                TextButton(
                  onPressed: () {
                    // ไปหน้าถัดไปเลยโดยไม่ต้องมี dialog
                    Navigator.pushNamed(context, '/device');
                  },
                  child: Text(
                    'ทดสอบ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
