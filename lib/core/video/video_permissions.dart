// lib/core/video/video_permissions.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class VideoPermissions {
  /// ตรวจสอบและขอ permissions ที่จำเป็นสำหรับ video call
  static Future<bool> requestVideoCallPermissions(BuildContext context) async {
    try {
      // ตรวจสอบ permissions ที่ต้องการ
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      print('Debug: Camera permission: $cameraStatus');
      print('Debug: Microphone permission: $microphoneStatus');

      // ถ้ามี permission แล้ว return true
      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
        return true;
      }

      // ขอ permissions
      final permissions = await _requestPermissions();

      // ตรวจสอบผลลัพธ์
      final allGranted = permissions.values.every((status) => status.isGranted);

      if (!allGranted) {
        // แสดง dialog อธิบายความจำเป็น
        await _showPermissionDialog(context, permissions);
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      _showErrorDialog(context, 'เกิดข้อผิดพลาดในการขอสิทธิ์: $e');
      return false;
    }
  }

  /// ขอ permissions ที่จำเป็น
  static Future<Map<Permission, PermissionStatus>> _requestPermissions() async {
    return await [Permission.camera, Permission.microphone].request();
  }

  /// ตรวจสอบสถานะ permissions ปัจจุบัน
  static Future<Map<String, bool>> checkCurrentPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    return {
      'camera': cameraStatus.isGranted,
      'microphone': microphoneStatus.isGranted,
      'cameraBlocked': cameraStatus.isPermanentlyDenied,
      'microphoneBlocked': microphoneStatus.isPermanentlyDenied,
    };
  }

  /// แสดง dialog เมื่อไม่ได้รับ permission
  static Future<void> _showPermissionDialog(
    BuildContext context,
    Map<Permission, PermissionStatus> permissions,
  ) async {
    final cameraStatus = permissions[Permission.camera];
    final microphoneStatus = permissions[Permission.microphone];

    String message = 'แอปต้องการสิทธิ์เข้าถึง:\n\n';

    if (cameraStatus != null && !cameraStatus.isGranted) {
      message += '📷 กล้อง - สำหรับการแสดงวิดีโอ\n';
    }

    if (microphoneStatus != null && !microphoneStatus.isGranted) {
      message += '🎤 ไมโครโฟน - สำหรับการสื่อสาร\n';
    }

    message += '\nโปรดอนุญาตสิทธิ์เหล่านี้เพื่อใช้งาน Video Call';

    final hasPermanentlyDenied = permissions.values.any(
      (status) => status.isPermanentlyDenied,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ต้องการสิทธิ์เข้าถึง'),
          content: Text(message),
          actions: [
            if (hasPermanentlyDenied) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AppSettings.openAppSettings();
                },
                child: const Text('เปิดการตั้งค่า'),
              ),
            ] else ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _requestPermissions();
                },
                child: const Text('อนุญาต'),
              ),
            ],
          ],
        );
      },
    );
  }

  /// แสดง dialog ข้อผิดพลาด
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  /// สร้าง Widget แสดงสถานะ permissions
  static Widget buildPermissionStatus() {
    return FutureBuilder<Map<String, bool>>(
      future: checkCurrentPermissions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final permissions = snapshot.data!;

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'สถานะสิทธิ์การเข้าถึง',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      permissions['camera'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: permissions['camera'] == true
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'กล้อง: ${permissions['camera'] == true ? 'อนุญาต' : 'ไม่อนุญาต'}',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      permissions['microphone'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: permissions['microphone'] == true
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ไมโครโฟน: ${permissions['microphone'] == true ? 'อนุญาต' : 'ไม่อนุญาต'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
