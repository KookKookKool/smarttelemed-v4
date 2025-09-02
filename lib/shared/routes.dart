// Shared routes for all applications
import 'package:flutter/material.dart';

// Import all app route modules
import 'package:smarttelemed_v4/apps/vhv_app/main_vhv.dart';
import 'package:smarttelemed_v4/apps/patient_app/main_patient.dart';
import 'package:smarttelemed_v4/apps/doctor_app/main_doctor.dart';
import 'package:smarttelemed_v4/apps/vhv_app/dashboard_screen.dart';

// Shared services
import 'package:smarttelemed_v4/shared/services/appoint/appoint_screen.dart';
import 'package:smarttelemed_v4/shared/services/appoint/appoint_table.dart';
import 'package:smarttelemed_v4/shared/services/appoint/make_appointment_screen.dart';
import 'package:smarttelemed_v4/shared/services/notes/record_note_screen.dart';
import 'package:smarttelemed_v4/shared/services/video/videocall_selection_screen.dart';
import 'package:smarttelemed_v4/shared/services/settings/settings_screen.dart';
import 'package:smarttelemed_v4/shared/services/device/connect/device_connect.dart';
import 'package:smarttelemed_v4/shared/services/device/connect/device_settings.dart';
import 'package:smarttelemed_v4/shared/services/vitalsign/vitalsign_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getAllRoutes() {
    final Map<String, WidgetBuilder> routes = {};
    
    // Add routes from each app
    routes.addAll(VHVApp.getRoutes());
    routes.addAll(PatientApp.getRoutes());
    routes.addAll(DoctorApp.getRoutes());
    
    // Add shared service routes
    routes.addAll({
      '/general': (context) => const DashboardScreen(), // General users go to dashboard  
      '/hospital': (context) => const DashboardScreen(), // Hospital users go to dashboard
      '/appoint': (context) => const AppointScreen(),
      '/appointtable': (context) => const AppointTableScreen(),
      '/makeAppointment': (context) => const MakeAppointmentScreen(),
      '/recordNote': (context) => const RecordNoteScreen(),
      '/videocall': (context) => const VideoCallSelectionScreen(),
      '/settings': (context) => const SettingScreen(),
      '/deviceConnect': (context) => const DeviceConnectPage(),
      '/devicesetting': (context) => const DeviceSettingPage(),
      '/vitalsign': (context) => const VitalSignScreen(),
    });
    
    return routes;
  }
}