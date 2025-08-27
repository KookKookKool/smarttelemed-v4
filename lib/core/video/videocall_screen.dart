// lib/core/doctor/videocall_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';
import 'package:smarttelemed_v4/core/video/video_call_manager.dart';
import 'package:smarttelemed_v4/core/video/webview_video_call.dart';
import 'package:smarttelemed_v4/core/video/video_permissions.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({Key? key}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallManager _callManager = VideoCallManager();
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _callManager.addListener(_onCallStateChanged);
  }

  @override
  void dispose() {
    _callManager.removeListener(_onCallStateChanged);
    super.dispose();
  }

  void _onCallStateChanged() {
    if (mounted) {
      setState(() {
        _isInitializing = _callManager.state == VideoCallState.connecting;
        _errorMessage = _callManager.errorMessage;
      });
    }
  }

  Future<void> _initializeCall() async {
    // ตรวจสอบและขอ permissions ก่อน
    final hasPermissions = await VideoPermissions.requestVideoCallPermissions(
      context,
    );

    if (!hasPermissions) {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'ต้องอนุญาตสิทธิ์กล้องและไมโครโฟนเพื่อใช้งาน Video Call';
      });
      return;
    }

    final success = await _callManager.startCall(
      participantName: 'Patient_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!success && mounted) {
      setState(() {
        _isInitializing = false;
        _errorMessage = _callManager.errorMessage ?? 'ไม่สามารถเริ่มการโทรได้';
      });
    }
  }

  void _endCall() {
    _callManager.endCall();
    Navigator.pushReplacementNamed(context, '/doctorPending');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: _endCall,
        ),
        title: const Text(
          'พบแพทย์',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: Colors.black87,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_callManager.state == VideoCallState.connected) {
      return _buildVideoCallView();
    }

    return _buildLoadingView();
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'กำลังเชื่อมต่อกับแพทย์...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // แสดงสถานะ permissions ถ้าเป็น permission error
              if (_errorMessage?.contains('สิทธิ์') == true ||
                  _errorMessage?.contains('กล้อง') == true ||
                  _errorMessage?.contains('ไมโครโฟน') == true)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: VideoPermissions.buildPermissionStatus(),
                ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitializing = true;
                      });
                      _initializeCall();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ลองใหม่'),
                  ),
                  ElevatedButton(
                    onPressed: _endCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCallView() {
    final webViewUrl = _callManager.getWebViewUrl();

    if (webViewUrl == null) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        // WebView สำหรับ OpenVidu
        WebViewVideoCall(
          webViewUrl: webViewUrl,
          onCallEnded: _endCall,
          onError: (error) {
            setState(() {
              _errorMessage = error;
            });
          },
        ),

        // ชื่อแพทย์ด้านบนขวา
        Positioned(
          top: 8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'พญ.ลลิตา สมอง #11111',
              style: TextStyle(
                color: Colors.white.withOpacity(.9),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
