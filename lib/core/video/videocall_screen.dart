import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isWebViewError = false; // Track if this is a WebView-specific error

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
    // Navigate to pending screen as requested
    Navigator.pushReplacementNamed(context, '/doctorPending');
  }

  Future<void> _openInExternalBrowser() async {
    final webViewUrl = _callManager.getWebViewUrl();
    if (webViewUrl != null) {
      try {
        // Use Android Intent to open browser
        const platform = MethodChannel('smarttelemed/external_browser');
        await platform.invokeMethod('openBrowser', {'url': webViewUrl});
      } catch (e) {
        print('Failed to open external browser: $e');
        // Fallback: copy URL to clipboard
        await _copyUrlToClipboard();
      }
    }
  }

  Future<void> _copyUrlToClipboard() async {
    final webViewUrl = _callManager.getWebViewUrl();
    if (webViewUrl != null) {
      await Clipboard.setData(ClipboardData(text: webViewUrl));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'คัดลอกลิงก์แล้ว\nกรุณานำไปเปิดในเบราว์เซอร์ Chrome หรือ Safari',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
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

              // Show WebView-specific help if it's a WebView error
              if (_isWebViewError) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info, color: Colors.orange, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'ปัญหา WebView Camera/Microphone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'แอปไม่สามารถเข้าถึงกล้องและไมโครโฟนผ่าน WebView ได้\nแนะนำให้เปิดในเบราว์เซอร์ภายนอกแทน',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
              
              // Action buttons
              if (_isWebViewError) ...[
                // WebView error - show browser options
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openInExternalBrowser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('เปิดในเบราว์เซอร์', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _copyUrlToClipboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.copy),
                        label: const Text('คัดลอกลิงก์', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _isInitializing = true;
                                _isWebViewError = false;
                              });
                              _initializeCall();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ลองใหม่'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _endCall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ยกเลิก'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                // Regular error - show normal options
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
              // Check if this is a WebView-specific permission error
              _isWebViewError = error.contains('WebView') || 
                               error.contains('NotAllowedError') || 
                               error.contains('Permission denied');
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

        // Floating action button to open in external browser
        Positioned(
          top: 60,
          right: 12,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: "openBrowser",
                onPressed: _openInExternalBrowser,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: const Icon(Icons.open_in_browser, size: 20),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: "copyUrl",
                onPressed: _copyUrlToClipboard,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: const Icon(Icons.copy, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
