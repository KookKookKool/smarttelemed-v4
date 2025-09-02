import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native_videocall_screen.dart';

/// Video Call Selection Screen - ไปหน้า Native OpenVidu Call โดยตรง
/// เชื่อมต่อ OpenVidu โดยตรงผ่าน API แทน WebView เพื่อแก้ปัญหากล้องไมค์
class VideoCallSelectionScreen extends StatelessWidget {
  final String? userId;
  final String? sessionId;

  const VideoCallSelectionScreen({super.key, this.userId, this.sessionId});

  @override
  Widget build(BuildContext context) {
    // ไปหน้า Native OpenVidu Call โดยตรงเลย
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NativeVideoCallScreen(userId: userId, sessionId: sessionId),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'กำลังเตรียม Native OpenVidu Call...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'เชื่อมต่อ OpenVidu โดยตรง • แก้ปัญหากล้องไมค์',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
