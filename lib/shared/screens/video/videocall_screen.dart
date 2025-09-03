import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smarttelemed_v4/storage/storage.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({Key? key}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasPermissions = false;
  String? _errorMessage;
  // Debug overlay fields
  String? _debugPublicId;
  String? _debugApiResponse;
  String? _debugSessionId;
  String _debugStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
  }

  Future<void> _initializeVideoCall() async {
    // ขอ permissions ก่อน
    await _requestPermissions();

    if (_hasPermissions) {
      _setupWebView();
    } else {
      setState(() {
        _errorMessage =
            'ต้องอนุญาตสิทธิ์กล้องและไมโครโฟนเพื่อใช้งาน Video Call';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // ขอ permissions สำหรับกล้องและไมโครโฟน
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      bool cameraGranted =
          statuses[Permission.camera] == PermissionStatus.granted;
      bool microphoneGranted =
          statuses[Permission.microphone] == PermissionStatus.granted;

      setState(() {
        _hasPermissions = cameraGranted && microphoneGranted;
      });

      debugPrint('📷 Camera permission: $cameraGranted');
      debugPrint('🎤 Microphone permission: $microphoneGranted');
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      setState(() {
        _hasPermissions = false;
      });
    }
  }

  void _setupWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('🔄 WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('🌐 Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('✅ Page finished loading: $url');
            // Enable media access first, then setup permissions and automation
            _enableWebViewMediaAccess();
            Future.delayed(const Duration(milliseconds: 500), () {
              _setupMediaPermissions();
              _autoLoginAndJoinRoom();
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView error: ${error.description}');
            setState(() {
              _errorMessage = 'ไม่สามารถโหลดหน้าเว็บได้: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'VideoCallHandler',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      );

    // Configure WebView for mobile with enhanced media support
    _webViewController.setUserAgent(
      'Mozilla/5.0 (Linux; Android 11; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Mobile Safari/537.36',
    );

    // Load OpenVidu page
    _webViewController.loadRequest(Uri.parse('https://openvidu.pcm-life.com'));
  }

  void _enableWebViewMediaAccess() {
    // Complete override of getUserMedia for WebView compatibility
    _webViewController.runJavaScript('''
      console.log('🔧 Enabling WebView media access...');
      
      // Create a comprehensive media stream mock
      if (typeof window !== 'undefined' && !window.webviewMediaPatched) {
        window.webviewMediaPatched = true;
        
        console.log('🎬 Creating MediaStream polyfill for WebView');
        
        // Create mock MediaStreamTrack
        function MockMediaStreamTrack(kind) {
          this.kind = kind;
          this.id = Math.random().toString(36).substr(2, 9);
          this.label = kind === 'video' ? 'WebView Camera' : 'WebView Microphone';
          this.enabled = true;
          this.muted = false;
          this.readyState = 'live';
          this.addEventListener = function() {};
          this.removeEventListener = function() {};
          this.stop = function() { this.readyState = 'ended'; };
          this.clone = function() { return new MockMediaStreamTrack(kind); };
        }
        
        // Create mock MediaStream
        function MockMediaStream(tracks) {
          this.id = Math.random().toString(36).substr(2, 9);
          this.active = true;
          this._tracks = tracks || [];
          
          this.getTracks = () => this._tracks;
          this.getVideoTracks = () => this._tracks.filter(t => t.kind === 'video');
          this.getAudioTracks = () => this._tracks.filter(t => t.kind === 'audio');
          
          this.addTrack = (track) => this._tracks.push(track);
          this.removeTrack = (track) => {
            const index = this._tracks.indexOf(track);
            if (index > -1) this._tracks.splice(index, 1);
          };
          
          this.clone = () => {
            const clonedTracks = this._tracks.map(t => t.clone());
            return new MockMediaStream(clonedTracks);
          };
          
          this.addEventListener = function() {};
          this.removeEventListener = function() {};
        }
        
        // Override getUserMedia completely
        if (navigator.mediaDevices) {
          const originalGetUserMedia = navigator.mediaDevices.getUserMedia;
          
          navigator.mediaDevices.getUserMedia = function(constraints) {
            console.log('🎭 Mock getUserMedia called with:', constraints);
            
            return new Promise((resolve, reject) => {
              // Always resolve with mock stream for WebView
              setTimeout(() => {
                const tracks = [];
                
                if (constraints.video) {
                  tracks.push(new MockMediaStreamTrack('video'));
                }
                if (constraints.audio) {
                  tracks.push(new MockMediaStreamTrack('audio'));
                }
                
                const mockStream = new MockMediaStream(tracks);
                console.log('✅ Mock stream created:', mockStream);
                resolve(mockStream);
              }, 100);
            });
          };
          
          console.log('✅ WebView getUserMedia completely overridden');
        }
        
        // Also override the deprecated getUserMedia
        if (navigator.getUserMedia) {
          navigator.getUserMedia = function(constraints, success, error) {
            console.log('🎭 Legacy getUserMedia called');
            navigator.mediaDevices.getUserMedia(constraints)
              .then(success)
              .catch(error);
          };
        }
      }
    ''');
  }

  Future<void> _setupMediaPermissions() async {
    try {
      await _webViewController.runJavaScript('''
        console.log('🎥 Setting up media permissions...');
        
        // Skip actual getUserMedia request since we have mock
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
          console.log('✅ getUserMedia is available (mocked)');
          
          // Just notify that media is "ready" with mock stream
          console.log('✅ Mock media stream is ready for WebView');
          VideoCallHandler.postMessage('media_success:Mock media access granted');
          
        } else {
          console.log('❌ getUserMedia not available');
          VideoCallHandler.postMessage('media_error:getUserMedia not supported');
        }
      ''');
    } catch (e) {
      debugPrint('❌ Error setting up media permissions: $e');
    }
  }

  Future<void> _autoLoginAndJoinRoom() async {
    // รอให้หน้าเว็บโหลดเสร็จสมบูรณ์
    await Future.delayed(const Duration(seconds: 3));

    try {
      // พยายามหา public_id (idCard) จาก storage ก่อน
      String? publicId;
      try {
        final patient = await PatientIdCardStorage.loadPatientIdCardData();
        if (patient != null && patient['idCard'] != null) {
          publicId = patient['idCard'].toString();
          debugPrint('🔎 Found patient idCard in Hive: $publicId');
          setState(() {
            _debugPublicId = publicId;
            _debugStatus = 'found_public_id';
          });
        }
      } catch (e) {
        debugPrint('❌ Error reading patient id from Hive: $e');
      }

      // หากเจอ publicId ให้เรียก API เพื่อขอ session/token แล้ว inject ลงใน WebView (localStorage)
      if (publicId != null && publicId.isNotEmpty) {
        try {
          final sessionId = await _fetchSessionId(publicId);
          if (sessionId != null && sessionId.isNotEmpty) {
            // ตั้ง token เป็น global variable บนหน้าเว็บ แล้วพยายามเรียก joinSession() พร้อม retry
            // Inject JS that creates its own OpenVidu session and connects using the token
            final js = '''(function(token){
              console.log('✅ Flutter injecting token and creating OpenVidu session');
              try {
                const OV = new OpenVidu();
                const session = OV.initSession();

                session.on('streamCreated', function(event) {
                  try {
                    session.subscribe(event.stream, 'subscriber');
                  } catch(e) { console.log('subscribe error', e); }
                });

                session.connect(token)
                  .then(() => {
                    try {
                      const publisher = OV.initPublisher('publisher');
                      session.publish(publisher);
                      console.log('✅ Connected and published via injected OpenVidu');
                    } catch(e) { console.log('publish error', e); }
                  })
                  .catch(error => {
                    console.log('❌ Error connecting injected OpenVidu session', error);
                  });
              } catch (e) {
                console.log('❌ Error in injected OpenVidu flow', e);
              }
            })('$sessionId');''';

            await _webViewController.runJavaScript(js);
            setState(() {
              _debugSessionId = sessionId;
              _debugStatus = 'fetched_session';
            });
            debugPrint(
              '✅ Injected sessionId and requested joinSession in WebView',
            );
          } else {
            debugPrint('⚠️ sessionId empty from API');
          }
        } catch (err) {
          debugPrint('❌ Error fetching/injecting sessionId: $err');
        }
      } else {
        debugPrint('⚠️ publicId not found - skipping token fetch');
      }

      // Auto-fill และ submit form
      await _webViewController.runJavaScript('''
        console.log('🚀 Starting auto-login process...');
        console.log('📍 Current URL:', window.location.href);
        console.log('📄 Page title:', document.title);
        
        // Override getUserMedia เพื่อให้ทำงานใน WebView
        function enhanceGetUserMedia() {
          console.log('🎥 Enhancing getUserMedia for WebView...');
          
          const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
          
          navigator.mediaDevices.getUserMedia = function(constraints) {
            console.log('📸 getUserMedia called with:', constraints);
            
            return originalGetUserMedia(constraints)
              .then(stream => {
                console.log('✅ Media stream obtained:', stream);
                console.log('📺 Video tracks:', stream.getVideoTracks().length);
                console.log('🎤 Audio tracks:', stream.getAudioTracks().length);
                
                // แจ้ง Flutter
                if (typeof VideoCallHandler !== 'undefined') {
                  VideoCallHandler.postMessage('media_ready');
                }
                
                return stream;
              })
              .catch(error => {
                console.error('❌ getUserMedia error:', error);
                
                // แจ้ง Flutter
                if (typeof VideoCallHandler !== 'undefined') {
                  VideoCallHandler.postMessage('media_error:' + error.message);
                }
                
                throw error;
              });
          };
        }
        
        // เรียกใช้ enhance function
        enhanceGetUserMedia();
        
        // รอให้ form elements พร้อม
        function waitForElement(selector, timeout = 15000) {
          return new Promise((resolve, reject) => {
            const startTime = Date.now();
            
            function check() {
              const element = document.querySelector(selector);
              if (element) {
                console.log('✅ Found element:', selector, element);
                resolve(element);
              } else if (Date.now() - startTime >= timeout) {
                console.log('⏰ Timeout waiting for:', selector);
                reject(new Error('Element not found: ' + selector));
              } else {
                setTimeout(check, 200);
              }
            }
            
            check();
          });
        }
        
        // ตรวจสอบ elements ที่มีในหน้า
        function inspectPage() {
          console.log('🔍 Inspecting page elements...');
          
          // ค้นหา input fields ทั้งหมด
          const inputs = document.querySelectorAll('input');
          console.log('📝 Found inputs:', inputs.length);
          inputs.forEach((input, index) => {
            console.log(\`Input \${index}:\`, input.type, input.name, input.id, input.placeholder, input.className);
          });
          
          // ค้นหา buttons ทั้งหมด
          const buttons = document.querySelectorAll('button');
          console.log('🔘 Found buttons:', buttons.length);
          buttons.forEach((button, index) => {
            console.log(\`Button \${index}:\`, button.textContent?.trim(), button.type, button.className, button.id);
          });
          
          // ค้นหา Angular components
          const angularElements = document.querySelectorAll('[ng-reflect-router-link], app-*');
          console.log('�️ Angular elements:', angularElements.length);
          angularElements.forEach((el, index) => {
            console.log(\`Angular \${index}:\`, el.tagName, el.className, el.getAttribute('ng-reflect-router-link'));
          });
        }
        
        // เรียก inspect ก่อน
        inspectPage();
        
        // ฟังก์ชันสำหรับไปยัง room page ตรงๆ
        function goToRoomPage() {
          console.log('🏠 Going directly to room page...');
          
          // ลองไปหน้า room ตรงๆ
          const roomUrls = [
            '/home?roomName=telemed-test',
            '/room/telemed-test',
            '/session/telemed-test',
            '/#/room/telemed-test'
          ];
          
          for (const roomUrl of roomUrls) {
            try {
              console.log('🔗 Trying URL:', roomUrl);
              
              if (roomUrl.includes('#')) {
                window.location.hash = roomUrl.split('#')[1];
              } else {
                window.location.href = window.location.origin + roomUrl;
              }
              
              setTimeout(() => {
                inspectPage();
                setTimeout(findAndJoinRoom, 2000);
              }, 1000);
              
              break;
            } catch (e) {
              console.log('❌ Failed to navigate to:', roomUrl, e);
            }
          }
        }
        
        // ฟังก์ชันสำหรับหา room input และ join
        function findAndJoinRoom() {
          console.log('� Looking for room input and join button...');
          
          // หา room input
          const roomSelectors = [
            'input[name="roomName"]',
            '.room-name-input', 
            'input[placeholder*="Room Name" i]',
            'input[placeholder*="room" i]',
            'input[name*="room" i]',
            'input[id*="room"]',
            'input[type="text"]',
            '#roomName'
          ];
          
          let roomInput = null;
          for (const selector of roomSelectors) {
            roomInput = document.querySelector(selector);
            if (roomInput) {
              console.log('✅ Found room input:', selector);
              break;
            }
          }
          
          if (roomInput) {
            // กรอกชื่อห้อง
            roomInput.value = 'telemed-test';
            roomInput.focus();
            
            // Trigger events
            ['input', 'change', 'keyup', 'blur'].forEach(eventType => {
              roomInput.dispatchEvent(new Event(eventType, { bubbles: true }));
            });
            
            console.log('✅ Room name filled: telemed-test');
            
            setTimeout(() => {
              // หาปุ่ม join (ใช้ข้อมูลจาก log)
              const joinSelectors = [
                '.join-btn',
                'button:contains("JOIN")',
                'button[type="submit"]',
                'button'
              ];
              
              let joinButton = null;
              for (const selector of joinSelectors) {
                if (selector.includes(':contains')) {
                  joinButton = Array.from(document.querySelectorAll('button')).find(btn => 
                    btn.textContent && btn.textContent.trim().toUpperCase() === 'JOIN'
                  );
                } else {
                  joinButton = document.querySelector(selector);
                  if (joinButton && !joinButton.textContent?.toLowerCase().includes('join')) {
                    continue; // ข้าม button ที่ไม่ใช่ join
                  }
                }
                
                if (joinButton) {
                  console.log('✅ Found join button:', joinButton.textContent?.trim(), selector);
                  break;
                }
              }
              
              if (joinButton) {
                console.log('🔘 Clicking join button...');
                joinButton.click();
                
                // รอเข้าห้องและ setup media
                setTimeout(() => {
                  setupVideoCallDetection();
                  VideoCallHandler.postMessage('room_joined');
                }, 3000);
              } else {
                console.log('❌ Join button not found');
                // ลองใช้ enter key
                if (roomInput) {
                  roomInput.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13 }));
                  setTimeout(() => {
                    setupVideoCallDetection();
                    VideoCallHandler.postMessage('room_joined');
                  }, 3000);
                }
              }
            }, 1000);
          } else {
            console.log('❌ Room input not found');
            // แสดง available inputs
            const allInputs = document.querySelectorAll('input');
            console.log('Available inputs:');
            allInputs.forEach((inp, i) => {
              console.log(\`Input \${i}:\`, inp.type, inp.placeholder, inp.name, inp.className);
            });
            
            // ลองอีกครั้งหลังจาก 2 วินาที
            setTimeout(findAndJoinRoom, 2000);
          }
        }
        
        // ฟังก์ชันสำหรับ detect video call controls
        function setupVideoCallDetection() {
          console.log('🎬 Setting up video call detection...');
          
          // ฟังการวางสาย
          const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
              // ตรวจหาปุ่มวางสาย
              const leaveSelectors = [
                'button[title*="leave" i]',
                'button[title*="Leave"]',
                'button[title*="disconnect" i]',
                'button[title*="end" i]',
                'button[title*="hang up" i]',
                '.leave-button',
                '.end-call',
                '.disconnect-button'
              ];
              
              leaveSelectors.forEach(selector => {
                const buttons = document.querySelectorAll(selector);
                buttons.forEach(button => {
                  if (!button.hasAttribute('data-listener-added')) {
                    button.setAttribute('data-listener-added', 'true');
                    button.addEventListener('click', () => {
                      console.log('📞 Call ended by user');
                      VideoCallHandler.postMessage('call_ended');
                    });
                  }
                });
              });
              
              // ตรวจหา video elements
              const videos = document.querySelectorAll('video');
              videos.forEach((video, index) => {
                if (!video.hasAttribute('data-monitored')) {
                  video.setAttribute('data-monitored', 'true');
                  console.log(\`📺 Monitoring video element \${index}:`, video.srcObject ? 'has stream' : 'no stream');
                }
              });
            });
          });
          
          observer.observe(document.body, {
            childList: true,
            subtree: true
          });
          
          // เช็ค video elements ที่มีอยู่
          setTimeout(() => {
            const videos = document.querySelectorAll('video');
            console.log('📺 Found video elements:', videos.length);
            videos.forEach((video, index) => {
              console.log(\`Video \${index}:`, video.srcObject ? 'active stream' : 'no stream', video.muted);
            });
          }, 2000);
        }
        
        // เริ่มกระบวนการ
        setTimeout(() => {
          // ตรวจสอบว่าอยู่หน้าไหน
          const currentPath = window.location.pathname + window.location.hash;
          console.log('📍 Current path:', currentPath);
          
          if (currentPath.includes('home') || currentPath === '/' || currentPath === '') {
            // อยู่หน้าหลัก ให้ไปหา room input
            findAndJoinRoom();
          } else {
            // อยู่หน้าอื่น ลองหา room input หรือ join button
            findAndJoinRoom();
          }
        }, 5000); // Wait 5 seconds for better stability
      ''');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error in auto-login: $e');
      setState(() {
        _errorMessage = 'ไม่สามารถเข้าห้องประชุมอัตโนมัติได้';
        _isLoading = false;
      });
    }
  }

  // POST public_id ไปยัง API เพื่อรับ session/token
  Future<String?> _fetchSessionId(String publicId) async {
    try {
      final uri = Uri.parse(
        'https://emr-life.com/clinic_master/clinic/Api/get_video',
      );
      final response = await http
          .post(uri, body: {'public_id': publicId})
          .timeout(const Duration(seconds: 10));

      debugPrint('🔁 get_video response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = response.body;
        setState(() {
          _debugApiResponse = body;
        });
        debugPrint('🔍 get_video body: $body');
        try {
          final jsonResp = json.decode(body);
          // พยายามดึง sessionId จากหลายตำแหน่งที่เป็นไปได้
          if (jsonResp is Map) {
            // Prefer token field (OpenVidu connection string), then sessionId fallbacks
            // Prefer token field (OpenVidu connection string), then sessionId fallbacks
            Future<String?> _saveAndReturnToken(dynamic tokRaw) async {
              try {
                String tok = tokRaw.toString();
                // If token looks like a URL containing token=..., extract the actual tok_... value
                final match = RegExp(r'token=([^&]+)').firstMatch(tok);
                final tokenVal = match != null
                    ? Uri.decodeComponent(match.group(1)!)
                    : tok;
                final patient =
                    await PatientIdCardStorage.loadPatientIdCardData();
                final updated = {...?patient, 'video_token': tokenVal};
                await PatientIdCardStorage.savePatientIdCardData(updated);
                debugPrint('💾 Saved video_token to PatientIdCardStorage');
                return tokenVal;
              } catch (e) {
                debugPrint('❌ Error saving video_token: $e');
                return tokRaw.toString();
              }
            }

            if (jsonResp['token'] != null)
              return await _saveAndReturnToken(jsonResp['token']);
            if (jsonResp['data'] != null && jsonResp['data']['token'] != null)
              return await _saveAndReturnToken(jsonResp['data']['token']);
            if (jsonResp['result'] != null &&
                jsonResp['result']['token'] != null)
              return await _saveAndReturnToken(jsonResp['result']['token']);
            // Backwards compat: sessionId fields
            if (jsonResp['sessionId'] != null)
              return jsonResp['sessionId'].toString();
            if (jsonResp['data'] != null &&
                jsonResp['data']['sessionId'] != null)
              return jsonResp['data']['sessionId'].toString();
            if (jsonResp['result'] != null &&
                jsonResp['result']['sessionId'] != null)
              return jsonResp['result']['sessionId'].toString();
          }
        } catch (e) {
          debugPrint('❌ Failed to parse get_video JSON: $e');
        }
        // fallback: return raw body if it's likely the token
        return body;
      }
    } catch (e) {
      debugPrint('❌ Error calling get_video: $e');
    }
    return null;
  }

  void _handleJavaScriptMessage(String message) {
    debugPrint('📨 Received message from WebView: $message');

    if (message.startsWith('media_error:')) {
      String error = message.substring('media_error:'.length);
      debugPrint('❌ Media error: $error');
      setState(() {
        _errorMessage = 'ไม่สามารถเข้าถึงกล้องหรือไมโครโฟนได้: $error';
        _isLoading = false;
      });
      return;
    }

    switch (message) {
      case 'media_ready':
        debugPrint('✅ Media devices ready');
        break;
      case 'room_joined':
        debugPrint('✅ Successfully joined room');
        // อาจแสดง toast หรือ update UI
        break;
      case 'call_ended':
        debugPrint('📞 Call ended, navigating to doctor pending...');
        _endCall();
        break;
    }
  }

  void _endCall() {
    // นำทางไปหน้า doctor pending
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
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_hasPermissions) {
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
              const SizedBox(height: 30),

              // แสดงปุ่มสำหรับ permission error
              if (_errorMessage?.contains('สิทธิ์') == true ||
                  _errorMessage?.contains('กล้อง') == true ||
                  _errorMessage?.contains('ไมโครโฟน') == true) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'ต้องอนุญาตสิทธิ์กล้องและไมโครโฟน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'กรุณาไปที่การตั้งค่าแอป และเปิดสิทธิ์การเข้าถึงกล้องและไมโครโฟน',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _initializeVideoCall();
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
    return Stack(
      children: [
        // WebView สำหรับ OpenVidu
        WebViewWidget(controller: _webViewController),

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

        // ปุ่มวางสายฉุกเฉิน
        Positioned(
          top: 60,
          right: 12,
          child: FloatingActionButton(
            mini: true,
            heroTag: "endCall",
            onPressed: _endCall,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Icon(Icons.call_end, size: 20),
          ),
        ),

        // Debug overlay (bottom-left)
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            width: 260,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'publicId: ${_debugPublicId ?? '-'}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'sessionId: ${_debugSessionId ?? '-'}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'status: ${_debugStatus}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'api:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(
                  height: 60,
                  child: SingleChildScrollView(
                    child: Text(
                      _debugApiResponse != null
                          ? (_debugApiResponse!.length > 180
                                ? _debugApiResponse!.substring(0, 180) + '...'
                                : _debugApiResponse!)
                          : '-',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
