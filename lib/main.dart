import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:smarttelemed_v4/shared/screens/device/dashboard/vitals.dart';
import 'package:smarttelemed_v4/shared/screens/device/dashboard/device_hub.dart';
import 'package:smarttelemed_v4/shared/widgets/time/th_time_screen.dart';
import 'package:smarttelemed_v4/shared/screens/splash/plus_loader.dart';
import 'package:smarttelemed_v4/shared/screens/auth/auth_screen.dart';
import 'package:smarttelemed_v4/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Vitals.I.ensure(); // โหลดค่าล่าสุดจาก SharedPreferences
  await DeviceHub.I.ensureStarted();

  await Vitals.I.ensure(); // โหลดค่าล่าสุดจาก SharedPreferences
  await DeviceHub.I.ensureStarted(); // เริ่มศูนย์กลาง BLE ตั้งแต่บูต
  await initializeDateFormatting('th_TH');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [appRouteObserver],
      title: 'Smart Telemed V4',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const PlusLoaderPage(),
      routes: AppRoutes.routes,
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
            child: PlusLoader(size: 120, onCompleted: _goToAuthScreen),
          ),
        ),
      ),
    );
  }
}
