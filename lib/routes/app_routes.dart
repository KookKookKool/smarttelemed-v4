import 'package:flutter/material.dart';

// Shared screens
import 'package:smarttelemed_v4/shared/screens/splash/plus_loader.dart';
import 'package:smarttelemed_v4/shared/screens/auth/auth_screen.dart';
import 'package:smarttelemed_v4/shared/screens/splash/splash_screen.dart';
import 'package:smarttelemed_v4/shared/screens/settings/settings_screen.dart';
import 'package:smarttelemed_v4/shared/screens/notes/record_note_screen.dart';
import 'package:smarttelemed_v4/shared/screens/video/videocall_selection_screen.dart';
import 'package:smarttelemed_v4/shared/screens/device/connect/device_connect.dart';
import 'package:smarttelemed_v4/shared/screens/device/connect/device_settings.dart';
import 'package:smarttelemed_v4/shared/screens/vitalsign/vitalsign_screen.dart';

// VHV app screens
import 'package:smarttelemed_v4/apps/vhv/device_screen.dart';
import 'package:smarttelemed_v4/apps/vhv/login_qrcam.dart';
import 'package:smarttelemed_v4/apps/vhv/login_token.dart';
import 'package:smarttelemed_v4/apps/vhv/idcard/idcard_loginscreen.dart';
import 'package:smarttelemed_v4/apps/vhv/idcard/idcard_insertscreen.dart';
import 'package:smarttelemed_v4/apps/vhv/idcard/idcard_loader.dart';
import 'package:smarttelemed_v4/apps/vhv/dashboard_screen.dart';
import 'package:smarttelemed_v4/apps/vhv/profile_screen.dart';

// Personal/Patient app screens
import 'package:smarttelemed_v4/apps/personal/idcard/idcard_pt_insertscreen.dart';
import 'package:smarttelemed_v4/apps/personal/idcard/idcard_pt_loader.dart';
import 'package:smarttelemed_v4/apps/personal/profilept_screen.dart';
import 'package:smarttelemed_v4/apps/personal/mainpt_screen.dart';

// Hospital app screens
import 'package:smarttelemed_v4/apps/hospital/appoint/appoint_screen.dart';
import 'package:smarttelemed_v4/apps/hospital/doctor/doctor_screen.dart';
import 'package:smarttelemed_v4/apps/hospital/appoint/appoint_table.dart';
import 'package:smarttelemed_v4/apps/hospital/doctor/doctor_pending.dart';
import 'package:smarttelemed_v4/apps/hospital/appoint/make_appointment_screen.dart';
import 'package:smarttelemed_v4/apps/hospital/doctor/doctor_result_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
        // Shared routes
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/device': (context) => const DeviceScreen(),
        '/settings': (context) => const SettingScreen(),
        '/recordNote': (context) => const RecordNoteScreen(),
        '/videocall': (context) => const VideoCallSelectionScreen(),
        '/deviceConnect': (context) => const DeviceConnectPage(),
        '/devicesetting': (context) => const DeviceSettingPage(),
        '/vitalsign': (context) => const VitalSignScreen(),

        // VHV routes
        '/general': (context) => const DashboardScreen(), // General users go to dashboard
        '/loginToken': (context) => const LoginTokenPage(),
        '/loginQRCam': (context) => const LoginQrCamPage(),
        '/idcardlogscreen': (context) => const IdCardLoginScreen(),
        '/idcardlog': (context) => const IdCardLoginScreen(),
        '/idcardinsert': (context) => const IdCardInsertScreen(),
        '/idcardloader': (context) => const IdCardLoader(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),

        // Personal/Patient routes
        '/addcardpt': (context) => const IdCardPtInsertScreen(),
        '/idcardptloader': (context) => const IdCardPtLoader(),
        '/profilept': (context) => const ProfilePtScreen(),
        '/mainpt': (context) => const MainPtScreen(),

        // Hospital routes
        '/hospital': (context) => const DashboardScreen(), // Hospital users go to dashboard
        '/appoint': (context) => const AppointScreen(),
        '/doctor': (context) => const DoctorScreen(),
        '/appointtable': (context) => const AppointTableScreen(),
        '/doctorPending': (context) => const DoctorPendingScreen(),
        '/makeAppointment': (context) => const MakeAppointmentScreen(),
        '/doctorResult': (context) => const DoctorResultScreen(),
      };
}