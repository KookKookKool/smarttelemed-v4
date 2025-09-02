// VHV (Village Health Volunteer) App Main Entry Point
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/apps/vhv_app/dashboard_screen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/profile_screen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/device_screen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/login_token.dart';
import 'package:smarttelemed_v4/apps/vhv_app/login_qrcam.dart';
import 'package:smarttelemed_v4/apps/vhv_app/idcard/idcard_loginscreen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/idcard/idcard_insertscreen.dart';
import 'package:smarttelemed_v4/apps/vhv_app/idcard/idcard_loader.dart';

// Shared services
import 'package:smarttelemed_v4/shared/services/auth/auth_screen.dart';
import 'package:smarttelemed_v4/shared/services/splash/splash_screen.dart';

class VHVApp {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/auth': (context) => const AuthScreen(),
      '/splash': (context) => const SplashScreen(),
      '/dashboard': (context) => const DashboardScreen(),
      '/profile': (context) => const ProfileScreen(),
      '/device': (context) => const DeviceScreen(),
      '/loginToken': (context) => const LoginTokenPage(),
      '/loginQRCam': (context) => const LoginQrCamPage(),
      '/idcardlogscreen': (context) => const IdCardLoginScreen(),
      '/idcardlog': (context) => const IdCardLoginScreen(),
      '/idcardinsert': (context) => const IdCardInsertScreen(),
      '/idcardloader': (context) => const IdCardLoader(),
    };
  }
  
  static String get initialRoute => '/auth';
}