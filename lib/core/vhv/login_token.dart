import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/app_colors.dart';
import 'package:smarttelemed_v4/utils/responsive.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_qrcam.dart';

class LoginTokenPage extends StatefulWidget {
  const LoginTokenPage({Key? key}) : super(key: key);

  @override
  State<LoginTokenPage> createState() => _LoginTokenPageState();
}

class _LoginTokenPageState extends State<LoginTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  String? _errorText;

  void _onConfirm() {
    // final token = _tokenController.text.trim();
    // if (token.isEmpty) {
    //   setState(() {
    //     _errorText = 'กรุณากรอก Token';
    //   });
    //   return;
    // }
    // if (token.length != 1) {
    //   setState(() {
    //     _errorText = 'กรุณากรอก Token ให้ครบ 13 หลัก';
    //   });
    //   return;
    // }
    // setState(() {
    //   _errorText = null;
    // });
    Navigator.pushNamed(context, '/device');
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
