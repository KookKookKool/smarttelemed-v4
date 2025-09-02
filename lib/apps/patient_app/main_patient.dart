// Patient App Main Entry Point
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/apps/patient_app/mainpt_screen.dart';
import 'package:smarttelemed_v4/apps/patient_app/profilept_screen.dart';
import 'package:smarttelemed_v4/apps/patient_app/idcard/idcard_pt_insertscreen.dart';
import 'package:smarttelemed_v4/apps/patient_app/idcard/idcard_pt_loader.dart';

// Shared services
import 'package:smarttelemed_v4/shared/services/auth/auth_screen.dart';
import 'package:smarttelemed_v4/shared/services/splash/splash_screen.dart';

class PatientApp {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/auth': (context) => const AuthScreen(),
      '/splash': (context) => const SplashScreen(),
      '/mainpt': (context) => const MainPtScreen(),
      '/profilept': (context) => const ProfilePtScreen(),
      '/addcardpt': (context) => const IdCardPtInsertScreen(),
      '/idcardptloader': (context) => const IdCardPtLoader(),
    };
  }
  
  static String get initialRoute => '/auth';
}