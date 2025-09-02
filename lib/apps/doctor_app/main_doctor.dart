// Doctor App Main Entry Point
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/apps/doctor_app/doctor_screen.dart';
import 'package:smarttelemed_v4/apps/doctor_app/doctor_pending.dart';
import 'package:smarttelemed_v4/apps/doctor_app/doctor_result_screen.dart';

// Shared services
import 'package:smarttelemed_v4/shared/services/auth/auth_screen.dart';
import 'package:smarttelemed_v4/shared/services/splash/splash_screen.dart';

class DoctorApp {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/auth': (context) => const AuthScreen(),
      '/splash': (context) => const SplashScreen(),
      '/doctor': (context) => const DoctorScreen(),
      '/doctorPending': (context) => const DoctorPendingScreen(),
      '/doctorResult': (context) => const DoctorResultScreen(),
    };
  }
  
  static String get initialRoute => '/auth';
}