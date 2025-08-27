import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:smarttelemed_v4/core/video/video_config.dart';
import 'auto_login_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // ขอ permission สำหรับ camera และ microphone
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    print('Debug: Camera permission: $cameraStatus');
    print('Debug: Microphone permission: $microphoneStatus');

    List<Permission> permissionsToRequest = [];

    if (!cameraStatus.isGranted) {
      permissionsToRequest.add(Permission.camera);
    }

    if (!microphoneStatus.isGranted) {
      permissionsToRequest.add(Permission.microphone);
    }

    if (permissionsToRequest.isNotEmpty) {
      print('Requesting permissions: $permissionsToRequest');
      final results = await permissionsToRequest.request();

      for (var permission in results.keys) {
        final status = results[permission];
        print('Permission $permission: $status');

        if (status == PermissionStatus.permanentlyDenied) {
          widget.onError?.call(
            'กรุณาอนุญาตการเข้าถึงกล้องและไมโครโฟนในการตั้งค่าแอป',
          );
          return;
        }
      }
    }

    // เริ่มต้น WebView หลังจากได้ permission แล้ว
    _initializeWebView();
  }

  void _handleMediaPermissionError(String error) {
    print('Debug: Handling media permission error: $error');
    
    if (error.contains('NotAllowedError')) {
      // For WebView permission issues, provide external browser option
      _showWebViewErrorDialog(error);
    } else if (error.contains('NotFoundError')) {
      widget.onError?.call(
        'ไม่พบกล้องหรือไมโครโฟนในอุปกรณ์',
      );
    } else if (error.contains('NotReadableError')) {
      widget.onError?.call(
        'ไม่สามารถเข้าถึงกล้องหรือไมโครโฟนได้ อุปกรณ์อาจถูกใช้งานโดยแอปอื่น',
      );
    } else {
      _showWebViewErrorDialog(error);
    }
  }

  void _showWebViewErrorDialog(String error) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('WebView ไม่สามารถเข้าถึงกล้องและไมโครโฟน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WebView ในแอปไม่สามารถเข้าถึงกล้องและไมโครโฟนได้ เนื่องจากข้อจำกัดของระบบ',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'วิธีแก้ไข:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. คัดลอก URL และเปิดในเบราว์เซอร์ภายนอก'),
              Text('2. หรือลองปิดแอปและเปิดใหม่'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ข้อผิดพลาด: $error',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyUrlToClipboard();
              },
              child: Text('คัดลอก URL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCallEnded?.call();
              },
              child: Text('ปิด'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reloadWebView();
              },
              child: Text('ลองใหม่'),
            ),
          ],
        );
      },
    );
  }

  void _copyUrlToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.webViewUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('คัดลอก URL แล้ว! ไปเปิดในเบราว์เซอร์ภายนอก'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _reloadWebView() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller?.reload();
  }

  void _handleMediaTestResult(String message) {
    print('Debug: Media test result: $message');
    
    if (message == 'media_test_success') {
      print('WebView media test passed - camera and microphone should work');
      setState(() {
        _isLoading = false; // Hide loading since media is working
      });
    } else if (message.startsWith('media_test_failed:')) {
      final error = message.substring(18);
      print('WebView media test failed: $error');
      
      // Don't show error immediately, wait a bit in case it recovers
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          _handleMediaPermissionError(error);
        }
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      // Enable hardware acceleration and media features
      ..enableZoom(false)
      ..setBackgroundColor(Colors.black)
      // Add JavaScript channel for communication
      ..addJavaScriptChannel(
        'VideoCallChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('Debug: Received JS message: ${message.message}');
          if (message.message.startsWith('media_error:')) {
            final error = message.message.substring(12);
            print('Debug: Media error - $error');
            _handleMediaPermissionError(error);
          } else if (message.message == 'media_test_success' || message.message.startsWith('media_test_failed:')) {
            _handleMediaTestResult(message.message);
          }
        },
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
            _controller?.runJavaScript(
              AutoLoginHandler().multiMethodAutoLoginScript,
            );

            // Force WebView permissions without user prompt
            _controller?.runJavaScript('''
              console.log('Force-granting WebView media permissions...');
              
              // Override permissions API to always return granted
              if (navigator.permissions && navigator.permissions.query) {
                const originalQuery = navigator.permissions.query.bind(navigator.permissions);
                navigator.permissions.query = function(permissionDesc) {
                  console.log('Overriding permission query for:', permissionDesc.name);
                  
                  // Always return granted for media permissions
                  if (permissionDesc.name === 'camera' || permissionDesc.name === 'microphone') {
                    return Promise.resolve({
                      state: 'granted',
                      onchange: null
                    });
                  }
                  
                  return originalQuery(permissionDesc);
                };
              }
              
              // Override getUserMedia to bypass permission checks
              if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
                
                navigator.mediaDevices.getUserMedia = function(constraints) {
                  console.log('Force-enabled getUserMedia called with:', JSON.stringify(constraints));
                  
                  // Very basic constraints that WebView can handle
                  const forcedConstraints = {};
                  
                  if (constraints.video) {
                    forcedConstraints.video = {
                      width: { exact: 640 },
                      height: { exact: 480 },
                      frameRate: { exact: 15 }
                    };
                  }
                  
                  if (constraints.audio) {
                    forcedConstraints.audio = true;
                  }
                  
                  console.log('Using forced constraints:', JSON.stringify(forcedConstraints));
                  
                  // Try original implementation first
                  return originalGetUserMedia(forcedConstraints)
                    .catch(function(error) {
                      console.error('Forced getUserMedia failed:', error.name, error.message);
                      
                      // Try even simpler constraints
                      const simpleConstraints = {
                        video: constraints.video ? true : false,
                        audio: constraints.audio ? true : false
                      };
                      
                      console.log('Trying simple constraints:', JSON.stringify(simpleConstraints));
                      
                      if (window.VideoCallChannel) {
                        VideoCallChannel.postMessage('media_error:' + error.name + ' - ' + error.message);
                      }
                      
                      return originalGetUserMedia(simpleConstraints);
                    });
                };
                
                // Test media access immediately
                console.log('Testing immediate media access...');
                navigator.mediaDevices.getUserMedia({ video: true, audio: true })
                  .then(function(stream) {
                    console.log('WebView media test successful!');
                    stream.getTracks().forEach(track => track.stop());
                    
                    if (window.VideoCallChannel) {
                      VideoCallChannel.postMessage('media_test_success');
                    }
                  })
                  .catch(function(error) {
                    console.error('WebView media test failed:', error.name, error.message);
                    
                    if (window.VideoCallChannel) {
                      VideoCallChannel.postMessage('media_test_failed:' + error.name + ' - ' + error.message);
                    }
                  });
              }
              
              console.log('WebView media permission override complete');
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
    // ลบการรับ call_ended message เพื่อไม่ให้วางสายเอง
    if (message.startsWith('error:')) {
      final error = message.substring(6);
      widget.onError?.call(error);
    } else if (message == 'permissions_granted') {
      print('Debug: WebView permissions granted');
    } else if (message.startsWith('permissions_denied:')) {
      final error = message.substring(19);
      widget.onError?.call(
        'ไม่ได้รับอนุญาตให้เข้าถึงกล้องหรือไมโครโฟน: $error',
      );
    } else if (message.startsWith('permissions_check:')) {
      final info = message.substring(18);
      print('Debug: Permissions status - $info');
    } else if (message == 'media_access_granted') {
      print('Debug: Media access granted successfully');
      setState(() {
        _isLoading = false; // ซ่อน loading เมื่อได้ media access แล้ว
      });
    } else if (message.startsWith('media_access_partial:')) {
      final info = message.substring(22);
      print('Debug: Partial media access - $info');
      if (info == 'video_only') {
        widget.onError?.call(
          'สามารถเข้าถึงกล้องได้ แต่ไม่สามารถเข้าถึงไมโครโฟนได้',
        );
      }
      setState(() {
        _isLoading = false;
      });
    } else if (message.startsWith('media_access_failed:')) {
      final error = message.substring(20);
      print('Debug: Media access failed - $error');
      widget.onError?.call('ไม่สามารถเข้าถึงกล้องหรือไมโครโฟน: $error');
    } else if (message.startsWith('media_error:')) {
      final error = message.substring(12);
      print('Debug: Media error - $error');
      widget.onError?.call('ข้อผิดพลาดการเข้าถึงสื่อ: $error');
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
    } else if (message == 'room_joined_successfully') {
      print(
        'Debug: Successfully joined video room - stopping auto-join attempts',
      );
    } else if (message == 'api_auth_success') {
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
    return Scaffold(
      body: Stack(
        children: [
          // WebView
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

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
                          _controller?.reload();
                        },
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showOptionsMenu();
        },
        backgroundColor: Colors.blue.withOpacity(0.8),
        child: Icon(Icons.more_vert, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ตัวเลือก Video Call',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('คัดลอก URL สำหรับเบราว์เซอร์ภายนอก'),
                subtitle: Text('ใช้เมื่อ WebView ไม่สามารถเข้าถึงกล้องได้'),
                onTap: () {
                  Navigator.pop(context);
                  _copyUrlToClipboard();
                },
              ),
              ListTile(
                leading: Icon(Icons.refresh),
                title: Text('รีโหลดหน้าเว็บ'),
                subtitle: Text('ลองโหลดใหม่เพื่อแก้ไขปัญหา'),
                onTap: () {
                  Navigator.pop(context);
                  _reloadWebView();
                },
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('ปิด Video Call'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onCallEnded?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
