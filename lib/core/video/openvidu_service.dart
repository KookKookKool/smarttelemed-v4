// lib/core/video/openvidu_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smarttelemed_v4/core/video/video_config.dart';
import 'auto_login_handler.dart';

class OpenViduService {
  static const String baseUrl = 'https://conference.pcm-life.com';
  static const String sessionId = 'Telemed_Test';

  // สร้าง session และ token สำหรับ OpenVidu
  static Future<String> createSession() async {
    try {
      // ใน production ควรมี proper authentication
      // ตอนนี้ใช้ session ID ตายตัวตามที่กำหนด
      return sessionId;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // สร้าง token สำหรับเข้าร่วม session
  static Future<String> generateToken({
    required String sessionId,
    String? participantName,
    String role = 'PUBLISHER', // PUBLISHER, SUBSCRIBER, MODERATOR
  }) async {
    try {
      // ใน production ควรเรียก OpenVidu REST API เพื่อสร้าง token
      // ตอนนี้ return mock token
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tokenData = {
        'sessionId': sessionId,
        'role': role,
        'participantName': participantName ?? 'User_$timestamp',
        'timestamp': timestamp,
      };

      // สร้าง simple token (ใน production ควรใช้ JWT)
      final token = base64Encode(utf8.encode(jsonEncode(tokenData)));
      return token;
    } catch (e) {
      throw Exception('Failed to generate token: $e');
    }
  }

  // สร้าง URL สำหรับ WebView
  static String buildWebViewUrl({
    required String token,
    String? participantName,
    bool audioEnabled = true,
    bool videoEnabled = true,
  }) {
    final params = <String, String>{
      'sessionName': sessionId,
      'participantName': participantName ?? 'TelemedUser',
      'audioEnabled': audioEnabled.toString(),
      'videoEnabled': videoEnabled.toString(),
      'token': token,
      // เพิ่ม auto-login credentials
      'userId': VideoConfig.defaultUserId,
      'password': VideoConfig.defaultPassword,
      'autoLogin': 'true',
    };

    final uri = Uri.parse(
      '$baseUrl/$sessionId',
    ).replace(queryParameters: params);

    // ใช้ authenticated URL
    return AutoLoginHandler.buildAuthenticatedUrl(uri.toString());
  }

  // ตรวจสอบสถานะการเชื่อมต่อ
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
