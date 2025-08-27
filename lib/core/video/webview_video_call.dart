// lib/core/video/webview_video_call.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:smarttelemed_v4/core/video/video_config.dart';
import 'auto_login_handler.dart';

class WebViewVideoCall extends StatefulWidget {
  final String webViewUrl;
  final VoidCallback? onCallEnded;
  final Function(String)? onError;

  const WebViewVideoCall({
    Key? key,
    required this.webViewUrl,
    this.onCallEnded,
    this.onError,
  }) : super(key: key);

  @override
  State<WebViewVideoCall> createState() => _WebViewVideoCallState();
}

class _WebViewVideoCallState extends State<WebViewVideoCall> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 SmartTelemed/1.0',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            print('Debug: WebView loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            print('Debug: WebView loaded: $url');

            // ใช้ comprehensive auto-login script
            _controller.runJavaScript(
              AutoLoginHandler.multiMethodAutoLoginScript,
            );

            // เพิ่ม script สำหรับแก้ไขปัญหากล้องมือถือ
            _controller.runJavaScript('''
              console.log('Setting up mobile camera fixes...');
              
              // Override getUserMedia for mobile compatibility
              if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
                
                navigator.mediaDevices.getUserMedia = function(constraints) {
                  console.log('getUserMedia called with:', constraints);
                  
                  // Ensure mobile-friendly constraints
                  if (constraints.video) {
                    if (typeof constraints.video === 'object') {
                      constraints.video = {
                        ...constraints.video,
                        facingMode: 'user', // Default to front camera
                        width: { ideal: 640 },
                        height: { ideal: 480 },
                        frameRate: { ideal: 30, max: 30 }
                      };
                    } else {
                      constraints.video = {
                        facingMode: 'user',
                        width: { ideal: 640 },
                        height: { ideal: 480 },
                        frameRate: { ideal: 30, max: 30 }
                      };
                    }
                  }
                  
                  return originalGetUserMedia(constraints).catch(function(error) {
                    console.error('Camera access error:', error);
                    
                    // Try with simpler constraints
                    if (constraints.video && typeof constraints.video === 'object') {
                      console.log('Retrying with simpler video constraints...');
                      return originalGetUserMedia({
                        video: true,
                        audio: constraints.audio
                      });
                    }
                    
                    throw error;
                  });
                };
              }
              
              // Set mobile-friendly viewport
              let viewport = document.querySelector('meta[name="viewport"]');
              if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                document.head.appendChild(viewport);
              }
              viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              
              // Enable WebRTC on mobile
              window.addEventListener('load', function() {
                if (window.RTCPeerConnection) {
                  console.log('WebRTC supported');
                  VideoCallChannel.postMessage('webrtc_supported');
                } else {
                  console.log('WebRTC not supported');
                  VideoCallChannel.postMessage('webrtc_not_supported');
                }
              });
              
              console.log('Mobile camera fixes applied');
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'เกิดข้อผิดพลาดในการโหลด: ${error.description}';
            });
            widget.onError?.call(error.description);
          },
          onNavigationRequest: (NavigationRequest request) {
            // อนุญาตทุก navigation ภายใน OpenVidu
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'VideoCallChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(widget.webViewUrl), headers: _buildAuthHeaders());
  }

  // สร้าง headers สำหรับ authentication
  Map<String, String> _buildAuthHeaders() {
    // สร้าง basic auth header
    final credentials =
        '${VideoConfig.defaultUserId}:${VideoConfig.defaultPassword}';
    final encoded = base64Encode(utf8.encode(credentials));

    return {
      'Authorization': 'Basic $encoded',
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/html',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 SmartTelemed/1.0',
    };
  }

  void _handleJavaScriptMessage(String message) {
    print('Debug: Received JS message: $message');

    // จัดการข้อความจาก JavaScript
    if (message == 'call_ended') {
      widget.onCallEnded?.call();
    } else if (message.startsWith('error:')) {
      final error = message.substring(6);
      widget.onError?.call(error);
    } else if (message == 'permissions_granted') {
      print('Debug: WebView permissions granted');
    } else if (message.startsWith('permissions_denied:')) {
      final error = message.substring(19);
      widget.onError?.call(
        'ไม่ได้รับอนุญาตให้เข้าถึงกล้องหรือไมโครโฟน: $error',
      );
    } else if (message == 'webrtc_not_supported') {
      widget.onError?.call('เบราว์เซอร์ไม่รองรับ Video Call');
    } else if (message == 'webrtc_supported') {
      print('Debug: WebRTC is supported');
    } else if (message == 'auto_login_attempted') {
      print('Debug: Auto-login attempted');
    } else if (message == 'credentials_filled') {
      print('Debug: Login credentials filled');
    } else if (message == 'login_submitted') {
      print('Debug: Login form submitted');
    } else if (message == 'form_submitted') {
      print('Debug: Form submitted directly');
    } else if (message == 'storage_auth_set') {
      print('Debug: Storage authentication set');
    } else if (message == 'auto_login_param_detected') {
      print('Debug: Auto-login URL parameter detected');
    } else if (message == 'api_auth_success') {
      print('Debug: API authentication successful');
    } else if (message == 'login_success_detected') {
      print('Debug: Login success detected');
      // อาจจะซ่อน loading indicator
    } else if (message == 'room_entered') {
      print('Debug: Video room entered successfully');
      // อาจจะแจ้งว่าเข้าห้องสำเร็จแล้ว
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView
        WebViewWidget(controller: _controller),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'กำลังเชื่อมต่อ...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Container(
            color: Colors.black87,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        _controller.reload();
                      },
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
