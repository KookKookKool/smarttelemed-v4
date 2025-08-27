// lib/core/video/video_config.dart
class VideoConfig {
  // OpenVidu Configuration
  static const String openViduUrl = 'https://conference.pcm-life.com';
  static const String sessionName = 'Telemed-Test';

  // Authentication
  static const String defaultUserId = 'user';
  static const String defaultPassword = 'minadadmin';

  // Video Call Settings
  static const bool defaultAudioEnabled = true;
  static const bool defaultVideoEnabled = true;
  static const int connectionTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // UI Settings
  static const String defaultDoctorName = 'พญ.ลลิตา สมอง #11111';
  static const String patientPrefix = 'Patient';

  // Error Messages
  static const String connectionErrorMessage =
      'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
  static const String sessionCreateErrorMessage = 'ไม่สามารถสร้าง session ได้';
  static const String tokenErrorMessage = 'ไม่สามารถสร้าง token ได้';
  static const String generalErrorMessage = 'เกิดข้อผิดพลาดในการเริ่มต้นการโทร';

  // WebView JavaScript
  static const String videoCallEndedMessage = 'call_ended';
  static const String videoCallErrorPrefix = 'error:';

  // Navigation
  static const String postCallRoute = '/doctorPending';
}
