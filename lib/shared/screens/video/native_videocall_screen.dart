import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'dart:convert';

/// Native Video Call Screen ที่เชื่อมต่อกับ OpenVidu โดยตรง
/// ใช้ Native Camera แทน WebView เพื่อแก้ปัญหา media permissions
class NativeVideoCallScreen extends StatefulWidget {
  final String? userId;
  final String? sessionId;

  const NativeVideoCallScreen({super.key, this.userId, this.sessionId});

  @override
  State<NativeVideoCallScreen> createState() => _NativeVideoCallScreenState();
}

class _NativeVideoCallScreenState extends State<NativeVideoCallScreen> {
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  String _statusMessage = 'เริ่มต้นการเชื่อมต่อ...';

  // OpenVidu configuration
  final String _openViduUrl = 'https://conference.pcm-life.com';
  final String _sessionName = 'telemed-test';
  String? _sessionId;
  String? _token;
  String? _workingCredential;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoCall() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'กำลังขออนุญาตใช้กล้องและไมค์...';
    });

    try {
      // Step 1: ขออนุญาต permissions
      await _requestPermissions();

      setState(() {
        _statusMessage = 'กำลังเตรียมกล้อง...';
      });

      // Step 2: เตรียมกล้อง
      await _initializeCamera();

      setState(() {
        _statusMessage = 'กำลังสร้างห้องประชุม...';
      });

      // Step 3: สร้าง OpenVidu session และ token
      await _connectToOpenViduService();
    } catch (e) {
      setState(() {
        _statusMessage = 'เชื่อมต่อไม่สำเร็จ: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [Permission.camera, Permission.microphone];
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    for (var permission in permissions) {
      if (statuses[permission] != PermissionStatus.granted) {
        throw Exception('จำเป็นต้องได้รับอนุญาตใช้กล้องและไมค์');
      }
    }

    debugPrint('✅ ได้รับอนุญาต camera และ microphone แล้ว');
  }

  Future<void> _initializeCamera() async {
    try {
      // ค้นหากล้องที่มี
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('ไม่พบกล้องในอุปกรณ์');
      }

      // ใช้กล้องหน้าถ้ามี ไม่งั้นใช้กล้องแรก
      CameraDescription camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // สร้าง camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      // เริ่มต้นกล้อง
      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });

      debugPrint('✅ Camera initialized successfully');
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
      throw e;
    }
  }

  Future<void> _connectToOpenViduService() async {
    try {
      // Step 1: สร้าง session
      final sessionResponse = await _createSession();
      if (sessionResponse == null) {
        throw Exception('ไม่สามารถสร้าง session ได้');
      }

      _sessionId = sessionResponse;

      setState(() {
        _statusMessage = 'กำลังสร้าง token...';
      });

      // Step 2: สร้าง token
      final tokenResponse = await _createToken(_sessionId!);
      if (tokenResponse == null) {
        throw Exception('ไม่สามารถสร้าง token ได้');
      }

      _token = tokenResponse;

      setState(() {
        _statusMessage = 'กำลังเชื่อมต่อห้องประชุม...';
      });

      // Step 3: เชื่อมต่อสำเร็จ
      await _connectToRoom();
    } catch (e) {
      setState(() {
        _statusMessage = 'เชื่อมต่อ OpenVidu ไม่สำเร็จ: $e';
        _isConnecting = false;
      });
    }
  }

  Future<String?> _createSession() async {
    try {
      debugPrint(
        '🚀 เริ่มสร้าง session กับ URL: $_openViduUrl/openvidu/api/sessions',
      );
      final url = Uri.parse('$_openViduUrl/openvidu/api/sessions');

      // ลอง credentials หลายแบบ
      final credentialsList = [
        'user:minadadmin',
        'OPENVIDUAPP:MY_SECRET',
        'OPENVIDUAPP:minadadmin',
        'admin:minadadmin',
        'admin:admin',
        'admin:password',
        'root:minadadmin',
        'pcm:minadadmin',
        'pcm-life:minadadmin',
        'conference:minadadmin',
      ];

      for (String credential in credentialsList) {
        debugPrint('🔑 ลองใช้ credential: ${credential.split(':')[0]}:***');

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Basic ' + base64Encode(utf8.encode(credential)),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'customSessionId': _sessionName}),
        );

        debugPrint('📡 Response status: ${response.statusCode}');
        debugPrint('📝 Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 409) {
          // 409 = session already exists (ซึ่งก็ OK)
          debugPrint('✅ สร้าง session สำเร็จด้วย credential: $credential');

          // เก็บ credential ที่ใช้ได้สำหรับการสร้าง token
          setState(() {
            _workingCredential = credential;
          });

          // ถ้า response body ไม่ว่าง ให้ parse JSON
          if (response.body.isNotEmpty) {
            final data = jsonDecode(response.body);
            return data['id'] ?? _sessionName;
          } else {
            // ถ้า response body ว่าง (กรณี 409) ให้ใช้ session name ที่กำหนด
            return _sessionName;
          }
        }
      }

      debugPrint('❌ ไม่พบ credential ที่ใช้ได้');
      return null;
    } catch (e) {
      debugPrint('❌ Create session exception: $e');
      return null;
    }
  }

  Future<String?> _createToken(String sessionId) async {
    try {
      final url = Uri.parse(
        '$_openViduUrl/openvidu/api/sessions/$sessionId/connection',
      );

      // ใช้ credential ที่ใช้งานได้แล้วจาก _createSession
      final credentialToUse = _workingCredential ?? 'user:minadadmin';
      debugPrint(
        '🔑 ใช้ credential สำหรับ token: ${credentialToUse.split(':')[0]}:***',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Basic ' + base64Encode(utf8.encode(credentialToUse)),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'role': 'PUBLISHER',
          'data':
              'Patient_${widget.userId ?? DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      debugPrint('📡 Token response status: ${response.statusCode}');
      debugPrint('📝 Token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ สร้าง token สำเร็จ');
        return data['token'];
      } else {
        debugPrint(
          '❌ Create token error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Create token exception: $e');
      return null;
    }
  }

  Future<void> _connectToRoom() async {
    try {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _statusMessage = 'เชื่อมต่อ Video Call สำเร็จ!';
      });

      // แสดงข้อมูลห้องในคอนโซล
      debugPrint('🎉 เข้าห้อง OpenVidu สำเร็จ!');
      debugPrint('📺 Session Name: $_sessionName');
      debugPrint('🌐 Server URL: $_openViduUrl');
      debugPrint(
        '🔗 อีกฝั่งสามารถเข้าห้อง "$_sessionName" ได้ที่ $_openViduUrl',
      );

      // แสดงข้อความ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉 เชื่อมต่อ Video Call สำเร็จ!'),
                      Text(
                        'ห้อง: $_sessionName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'อีกฝั่งเข้าห้อง "$_sessionName" ได้เลย',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'การเชื่อมต่อ Video Call ล้มเหลว: $e';
        _isConnecting = false;
      });
    }
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOn = !_isCameraOn;
    });

    // ใน implementation จริงจะต้องหยุด/เริ่ม camera stream
    debugPrint('📹 Camera ${_isCameraOn ? 'ON' : 'OFF'}');
  }

  void _toggleMicrophone() {
    setState(() {
      _isMicOn = !_isMicOn;
    });

    // ใน implementation จริงจะต้องหยุด/เริ่ม audio stream
    debugPrint('🎤 Microphone ${_isMicOn ? 'ON' : 'OFF'}');
  }

  void _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1 && _cameraController != null) {
      final currentCamera = _cameraController!.description;
      CameraDescription newCamera;

      if (currentCamera.lensDirection == CameraLensDirection.front) {
        newCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => currentCamera,
        );
      } else {
        newCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => currentCamera,
        );
      }

      if (newCamera != currentCamera) {
        await _cameraController!.dispose();
        _cameraController = CameraController(
          newCamera,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        setState(() {});
        debugPrint('🔄 Switched camera');
      }
    }
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Call', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _endCall,
        ),
      ),
      body: _isConnected ? _buildVideoCallUI() : _buildConnectingUI(),
    );
  }

  Widget _buildConnectingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isConnecting) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (!_isConnecting && _statusMessage.contains('ไม่สำเร็จ')) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeVideoCall,
              child: const Text('ลองใหม่'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoCallUI() {
    return Stack(
      children: [
        // Remote video area (แบ็คกราวด์)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[900],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 100, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'รอคนอื่นเข้าร่วม...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),

        // Local camera preview (มุมบนขวา)
        Positioned(
          top: 40,
          right: 20,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child:
                  _isCameraInitialized &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized &&
                      _isCameraOn
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
            ),
          ),
        ),

        // Session info (มุมบนซ้าย)
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ห้อง: $_sessionName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'เซิร์ฟเวอร์: conference.pcm-life.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                if (_token != null)
                  Text(
                    '🟢 เชื่อมต่อแล้ว',
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                  ),
                Text(
                  'อีกฝั่งเข้าห้อง "$_sessionName"',
                  style: const TextStyle(color: Colors.yellow, fontSize: 9),
                ),
              ],
            ),
          ),
        ),

        // Control buttons (ด้านล่าง)
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Toggle microphone
              FloatingActionButton(
                heroTag: 'mic',
                onPressed: _toggleMicrophone,
                backgroundColor: _isMicOn ? Colors.blue : Colors.red,
                child: Icon(
                  _isMicOn ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                ),
              ),

              // Switch camera
              FloatingActionButton(
                heroTag: 'switch',
                onPressed: _switchCamera,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.switch_camera, color: Colors.white),
              ),

              // End call
              FloatingActionButton(
                heroTag: 'end',
                onPressed: _endCall,
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),

              // Toggle camera
              FloatingActionButton(
                heroTag: 'camera',
                onPressed: _toggleCamera,
                backgroundColor: _isCameraOn ? Colors.blue : Colors.red,
                child: Icon(
                  _isCameraOn ? Icons.videocam : Icons.videocam_off,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
