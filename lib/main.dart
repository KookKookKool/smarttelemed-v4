import 'package:flutter/material.dart';
// VHV App imports
import 'package:smarttelemed_v4/apps/vhv_app/device_screen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/login_qrcam.dart';
import 'package:smarttelemed_v4/apps/vhv_app/login_token.dart';
import 'package:smarttelemed_v4/apps/vhv_app/idcard/idcard_loginscreen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/idcard/idcard_insertscreen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/idcard/idcard_loader.dart';
import 'package:smarttelemed_v4/apps/vhv_app/dashboard_screen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/profile_screen.dart';

// Patient App imports
import 'package:smarttelemed_v4/apps/patient_app/idcard/idcard_pt_insertscreen.dart';
import 'package:smarttelemed_v4/apps/patient_app/idcard/idcard_pt_loader.dart';
import 'package:smarttelemed_v4/apps/patient_app/profilept_screen.dart';
import 'package:smarttelemed_v4/apps/patient_app/mainpt_screen.dart';

// Doctor App imports
import 'package:smarttelemed_v4/apps/doctor_app/doctor_screen.dart';
import 'package:smarttelemed_v4/apps/doctor_app/doctor_pending.dart';
import 'package:smarttelemed_v4/apps/doctor_app/doctor_result_screen.dart';

// Shared Services imports
import 'package:smarttelemed_v4/shared/services/splash/plus_loader.dart';
import 'package:smarttelemed_v4/shared/services/auth/auth_screen.dart';
import 'package:smarttelemed_v4/shared/services/splash/splash_screen.dart';
import 'package:smarttelemed_v4/shared/services/appoint/appoint_screen.dart';
import 'package:smarttelemed_v4/shared/services/appoint/appoint_table.dart';
import 'package:smarttelemed_v4/shared/services/notes/record_note_screen.dart';
import 'package:smarttelemed_v4/shared/services/video/videocall_selection_screen.dart';
import 'package:smarttelemed_v4/shared/services/appoint/make_appointment_screen.dart';
import 'package:smarttelemed_v4/shared/services/settings/settings_screen.dart';
import 'package:smarttelemed_v4/shared/services/device/connect/device_connect.dart';
import 'package:smarttelemed_v4/shared/services/device/dashboard/vitals.dart';
import 'package:smarttelemed_v4/shared/services/device/dashboard/device_hub.dart';
import 'package:smarttelemed_v4/shared/services/device/connect/device_settings.dart';
import 'package:smarttelemed_v4/shared/widgets/time/th_time_screen.dart';
import 'package:smarttelemed_v4/shared/services/vitalsign/vitalsign_screen.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Shared routes import
import 'package:smarttelemed_v4/shared/routes.dart';
// Route observer import
import 'package:smarttelemed_v4/shared/widgets/time/th_time_screen.dart';

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
      routes: AppRoutes.getAllRoutes(),
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
