import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/core/vhv/device_screen.dart';
import 'package:smarttelemed_v4/core/vhv/login_qrcam.dart';
import 'package:smarttelemed_v4/core/vhv/login_token.dart';
import 'package:smarttelemed_v4/core/vhv/device_screen.dart';
import 'package:smarttelemed_v4/core/splash/plus_loader.dart';
import 'package:smarttelemed_v4/core/auth/auth_screen.dart';
import 'package:smarttelemed_v4/core/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Telemed V4',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const PlusLoaderPage(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/loginToken': (context) => const LoginTokenPage(),
        '/loginQRCam': (context) => const LoginQrCamPage(),
        '/device': (context) => const DeviceScreen(),
        // เพิ่ม routes อื่นๆ ตามต้องการ
      },
    );
  }
}

class PlusLoaderPage extends StatefulWidget {
  const PlusLoaderPage({Key? key}) : super(key: key);

  @override
  State<PlusLoaderPage> createState() => _PlusLoaderPageState();
}

class _PlusLoaderPageState extends State<PlusLoaderPage> {
  bool _zooming = false;

  void _goToSplashScreen() async {
    if (!mounted) return;
    setState(() {
      _zooming = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/splash');
  }

  void _goToAuthScreen() async {
  if (!mounted) return;
  setState(() {
    _zooming = true;
  });
  await Future.delayed(const Duration(milliseconds: 900));
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => const AuthScreen(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedScale(
          alignment: Alignment.center,
          onEnd: _goToSplashScreen,
          scale: _zooming ? 18.0 : 1.0,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeIn,
          child: AnimatedOpacity(
            opacity: _zooming ? 1.0 : 1.0,
            duration: const Duration(milliseconds: 900),
            child: PlusLoader(
              size: 120,
              onCompleted: _goToAuthScreen,
            ),
          ),
        ),
      ),
    );
  }
}