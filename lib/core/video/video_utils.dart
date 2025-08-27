// lib/core/video/video_utils.dart
import 'dart:convert';
import 'dart:math';
import 'package:smarttelemed_v4/core/video/video_config.dart';

class VideoUtils {
  /// สร้าง participant name ที่ unique
  static String generateParticipantName({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    final basePrefix = prefix ?? VideoConfig.patientPrefix;
    return '${basePrefix}_${timestamp}_$random';
  }

  /// สร้าง session ID ที่ unique (ถ้าต้องการใช้แบบ dynamic)
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Session_$timestamp';
  }

  /// เข้ารหัสข้อมูล token แบบง่าย
  static String encodeTokenData(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return base64Encode(utf8.encode(jsonString));
  }

  /// ถอดรหัสข้อมูล token
  static Map<String, dynamic>? decodeTokenData(String token) {
    try {
      final jsonString = utf8.decode(base64Decode(token));
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// ตรวจสอบว่า URL ถูกต้องหรือไม่
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// สร้าง query parameters สำหรับ WebView
  static Map<String, String> buildWebViewParams({
    required String sessionName,
    required String participantName,
    required String token,
    bool audioEnabled = true,
    bool videoEnabled = true,
    Map<String, String>? additionalParams,
  }) {
    final params = <String, String>{
      'sessionName': sessionName,
      'participantName': participantName,
      'token': token,
      'audioEnabled': audioEnabled.toString(),
      'videoEnabled': videoEnabled.toString(),
    };

    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    return params;
  }

  /// แปลง milliseconds เป็น duration string
  static String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// ตรวจสอบสถานะเครือข่าย (placeholder)
  static Future<bool> checkNetworkConnection() async {
    try {
      // ใน production ควรใช้ connectivity_plus package
      // ตอนนี้ return true
      return true;
    } catch (e) {
      return false;
    }
  }

  /// แปลง error message ให้เป็นภาษาไทย
  static String translateErrorMessage(String originalError) {
    final lowerError = originalError.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'ปัญหาการเชื่อมต่อเครือข่าย';
    }
    if (lowerError.contains('timeout')) {
      return 'การเชื่อมต่อหมดเวลา';
    }
    if (lowerError.contains('permission')) {
      return 'ไม่มีสิทธิ์เข้าถึงกล้องหรือไมโครโฟน';
    }
    if (lowerError.contains('camera')) {
      return 'ไม่สามารถเข้าถึงกล้องได้';
    }
    if (lowerError.contains('microphone')) {
      return 'ไม่สามารถเข้าถึงไมโครโฟนได้';
    }

    return 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
  }
}
