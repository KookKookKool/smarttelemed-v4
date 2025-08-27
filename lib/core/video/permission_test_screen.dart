// lib/core/video/permission_test_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/core/video/video_permissions.dart';

class PermissionTestScreen extends StatefulWidget {
  const PermissionTestScreen({Key? key}) : super(key: key);

  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  bool _isChecking = false;
  Map<String, bool>? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
    });

    final status = await VideoPermissions.checkCurrentPermissions();

    setState(() {
      _permissionStatus = status;
      _isChecking = false;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await VideoPermissions.requestVideoCallPermissions(context);

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ได้รับสิทธิ์เรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่ได้รับสิทธิ์'),
          backgroundColor: Colors.red,
        ),
      );
    }

    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบสิทธิ์ Video Call'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'สถานะสิทธิ์การเข้าถึง',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (_isChecking)
              const Center(child: CircularProgressIndicator())
            else if (_permissionStatus != null)
              Column(
                children: [
                  _buildPermissionTile(
                    'กล้อง',
                    _permissionStatus!['camera'] ?? false,
                    Icons.camera_alt,
                  ),
                  _buildPermissionTile(
                    'ไมโครโฟน',
                    _permissionStatus!['microphone'] ?? false,
                    Icons.mic,
                  ),
                  const SizedBox(height: 20),
                  if (_permissionStatus!['cameraBlocked'] == true ||
                      _permissionStatus!['microphoneBlocked'] == true)
                    const Card(
                      color: Colors.orange,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          '⚠️ บางสิทธิ์ถูกปฏิเสธอย่างถาวร กรุณาเปิดใน Settings',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'ขอสิทธิ์ Video Call',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _checkPermissions,
              child: const Text('ตรวจสอบสิทธิ์อีกครั้ง'),
            ),

            const SizedBox(height: 30),
            const Text(
              'หมายเหตุ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• กล้อง: สำหรับแสดงวิดีโอของคุณ\n'
              '• ไมโครโฟน: สำหรับการสื่อสารกับแพทย์\n'
              '• สิทธิ์เหล่านี้จำเป็นสำหรับ Video Call',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(String title, bool granted, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: granted ? Colors.green : Colors.red),
        title: Text(title),
        trailing: Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
        ),
        subtitle: Text(
          granted ? 'อนุญาต' : 'ไม่อนุญาต',
          style: TextStyle(
            color: granted ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
