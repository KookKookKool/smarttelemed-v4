import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/core/vhv/device_screen.dart';
import 'package:smarttelemed_v4/core/vhv/login_qrcam.dart';
import 'package:smarttelemed_v4/core/vhv/login_token.dart';
import 'package:smarttelemed_v4/core/vhv/device_screen.dart';
import 'package:smarttelemed_v4/core/splash/plus_loader.dart';
import 'package:smarttelemed_v4/core/auth/auth_screen.dart';
import 'package:smarttelemed_v4/core/splash/splash_screen.dart';
import 'package:smarttelemed_v4/core/vhv/idcard/idcard_loginscreen.dart';
import 'package:smarttelemed_v4/core/vhv/idcard/idcard_insertscreen.dart';
import 'package:smarttelemed_v4/core/vhv/idcard/idcard_loader.dart';
import 'package:smarttelemed_v4/core/vhv/dashboard_screen.dart';
import 'package:smarttelemed_v4/core/vhv/profile_screen.dart';
import 'package:smarttelemed_v4/pt/idcard/idcard_pt_insertscreen.dart';
import 'package:smarttelemed_v4/pt/idcard/idcard_pt_loader.dart';
import 'package:smarttelemed_v4/pt/profilept_screen.dart';
import 'package:smarttelemed_v4/pt/mainpt_screen.dart';
import 'package:smarttelemed_v4/core/appoint/appoint_screen.dart';
import 'package:smarttelemed_v4/core/doctor/doctor_screen.dart';
import 'package:smarttelemed_v4/core/appoint/appoint_table.dart';
import 'package:smarttelemed_v4/core/notes/record_note_screen.dart';
import 'package:smarttelemed_v4/core/video/videocall_screen.dart';
import 'package:smarttelemed_v4/core/doctor/doctor_pending.dart';
import 'package:smarttelemed_v4/core/appoint/make_appointment_screen.dart';
import 'package:smarttelemed_v4/core/setting/setting_screen.dart';
import 'package:smarttelemed_v4/core/doctor/doctor_result_screen.dart';
import 'package:smarttelemed_v4/core/device/device_connect.dart';

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
        '/idcardlog': (context) => const IdCardLoginScreen(),
        '/idcardinsert': (context) => IdCardInsertScreen(),
        '/idcardloader': (context) => const IdCardLoader(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/addcardpt': (context) => const IdCardPtInsertScreen(),
        '/idcardptloader': (context) => const IdCardPtLoader(),
        '/profilept': (context) => const ProfilePtScreen(),
        '/mainpt': (context) => const MainPtScreen(),
        '/appoint': (context) => const AppointScreen(),
        '/doctor': (context) => const DoctorScreen(),
        '/appointtable': (context) => const AppointTableScreen(),
        '/recordNote': (context) => const RecordNoteScreen(),
        '/videocall': (context) => const VideoCallScreen(),
        '/doctorPending': (context) => const DoctorPendingScreen(), // ใช้สำหรับหน้ารอแพทย์
        '/makeAppointment': (context) => const MakeAppointmentScreen(),
        '/settings': (context) => const SettingScreen(),
        '/doctorResult': (context) => const DoctorResultScreen(),
        '/deviceConnect': (context) => const DeviceConnectPage(),
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
        // pageBuilder: (context, animation1, animation2) => const AuthScreen(),
        pageBuilder: (context, animation1, animation2) => const IdCardInsertScreen(),
        
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
