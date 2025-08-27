// lib/core/video/webview_permissions.dart
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPermissions {
  /// สร้าง WebViewController ที่มีการตั้งค่า permissions สำหรับ video call
  static WebViewController createVideoCallController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Debug: Loading URL: $url');
          },
          onPageFinished: (String url) {
            print('Debug: Page loaded: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('Debug: WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Debug: Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(_buildUserAgent())
      ..addJavaScriptChannel(
        'VideoCallChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('Debug: JS Message: ${message.message}');
        },
      )
      ..loadRequest(Uri.parse(url));
  }

  /// สร้าง UserAgent ที่รองรับ WebRTC
  static String _buildUserAgent() {
    return 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 SmartTelemed/1.0';
  }

  /// JavaScript สำหรับขอ permissions ใน WebView
  static const String requestPermissionsJS = '''
    navigator.mediaDevices.getUserMedia({
      video: true,
      audio: true
    }).then(function(stream) {
      console.log('Permissions granted');
      VideoCallChannel.postMessage('permissions_granted');
    }).catch(function(error) {
      console.error('Permission denied:', error);
      VideoCallChannel.postMessage('permissions_denied:' + error.message);
    });
  ''';

  /// JavaScript สำหรับตรวจสอบ WebRTC support
  static const String checkWebRTCSupportJS = '''
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      VideoCallChannel.postMessage('webrtc_supported');
    } else {
      VideoCallChannel.postMessage('webrtc_not_supported');
    }
  ''';

  /// ตั้งค่า WebView สำหรับ OpenVidu
  static Map<String, String> getOpenViduHeaders() {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
  }

  /// สร้าง URL parameters สำหรับ WebView
  static String buildOpenViduUrl({
    required String baseUrl,
    required String sessionName,
    required String participantName,
    bool audioEnabled = true,
    bool videoEnabled = true,
  }) {
    final uri = Uri.parse('$baseUrl/$sessionName');
    final params = {
      'participantName': participantName,
      'audioEnabled': audioEnabled.toString(),
      'videoEnabled': videoEnabled.toString(),
      'webview': 'true', // บอก OpenVidu ว่าใช้ WebView
    };

    return uri.replace(queryParameters: params).toString();
  }
}
