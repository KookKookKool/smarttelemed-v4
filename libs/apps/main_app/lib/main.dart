import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import shared packages
import 'package:shared_core/shared_core.dart';
import 'package:shared_widgets/shared_widgets.dart';

// Import patient-specific screens from this app
import 'pt/idcard/idcard_pt_insertscreen.dart';
import 'pt/idcard/idcard_pt_loader.dart';
import 'pt/profilept_screen.dart';
import 'pt/mainpt_screen.dart';

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
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/general': (context) =>
            const DashboardScreen(), // General users go to dashboard
        '/hospital': (context) =>
            const DashboardScreen(), // Hospital users go to dashboard
        '/loginToken': (context) => const LoginTokenPage(),
        '/loginQRCam': (context) => const LoginQrCamPage(),
        '/device': (context) => const DeviceScreen(),
        '/idcardlogscreen': (context) => const IdCardLoginScreen(),
        '/idcardlog': (context) => const IdCardLoginScreen(),
        '/idcardinsert': (context) => const IdCardInsertScreen(),
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
        '/videocall': (context) => const VideoCallSelectionScreen(),
        '/doctorPending': (context) =>
            const DoctorPendingScreen(), // ใช้สำหรับหน้ารอแพทย์
        '/makeAppointment': (context) => const MakeAppointmentScreen(),
        '/settings': (context) => const SettingScreen(),
        '/doctorResult': (context) => const DoctorResultScreen(),
        '/deviceConnect': (context) => const DeviceConnectPage(),
        '/devicesetting': (context) => const DeviceSettingPage(),
        '/vitalsign': (context) => const VitalSignScreen(),
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
            child: PlusLoader(size: 120, onCompleted: _goToAuthScreen),
          ),
        ),
      ),
    );
  }
}
