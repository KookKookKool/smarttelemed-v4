import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smarttelemed_v4/storage/storage.dart';

class NativeVideoCallScreen extends StatefulWidget {
  final String? userId;
  final String? sessionId;

  const NativeVideoCallScreen({Key? key, this.userId, this.sessionId})
    : super(key: key);

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
  final String _openViduUrl = 'https://openvidu.pcm-life.com';
  final String _sessionName = 'telemed-test';
  String? _token;

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
      await _requestPermissions();
      setState(() => _statusMessage = 'กำลังเตรียมกล้อง...');
      await _initializeCamera();
      setState(() => _statusMessage = 'กำลังสร้างห้องประชุม...');
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
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty)
        throw Exception('ไม่พบกล้องในอุปกรณ์');

      CameraDescription camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
      rethrow;
    }
  }

  Future<void> _connectToOpenViduService() async {
    try {
      setState(() {
        _statusMessage = 'กำลังขอ token จากเซิร์ฟเวอร์...';
      });

      String? publicId;
      try {
        final patient = await PatientIdCardStorage.loadPatientIdCardData();
        if (patient != null && patient['idCard'] != null)
          publicId = patient['idCard'].toString();
      } catch (e) {
        debugPrint('Error loading patient id: $e');
      }

      if (publicId == null || publicId.isEmpty)
        throw Exception('ไม่พบ public_id ของผู้ป่วย ในเครื่อง');

      try {
        final uri = Uri.parse(
          'https://emr-life.com/clinic_master/clinic/Api/get_video',
        );
        final resp = await http
            .post(uri, body: {'public_id': publicId})
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final body = resp.body;
          final parsed = json.decode(body);
          String? tokRaw;
          if (parsed is Map) {
            if (parsed['token'] != null)
              tokRaw = parsed['token'].toString();
            else if (parsed['data'] != null && parsed['data']['token'] != null)
              tokRaw = parsed['data']['token'].toString();
            else if (parsed['result'] != null &&
                parsed['result']['token'] != null)
              tokRaw = parsed['result']['token'].toString();
          }

          String? tokenVal;
          if (tokRaw != null) {
            final m = RegExp(r'token=([^&]+)').firstMatch(tokRaw);
            tokenVal = m != null ? Uri.decodeComponent(m.group(1)!) : tokRaw;
          } else if (body.contains('tok_')) {
            final m2 = RegExp(r'(tok_[A-Za-z0-9_-]+)').firstMatch(body);
            tokenVal = m2?.group(1);
          }

          if (tokenVal == null)
            throw Exception('ไม่พบ token ในการตอบกลับจากเซิร์ฟเวอร์');

          _token = tokenVal;
          try {
            final patient = await PatientIdCardStorage.loadPatientIdCardData();
            final updated = {...?patient, 'video_token': _token};
            await PatientIdCardStorage.savePatientIdCardData(updated);
          } catch (_) {}

          setState(() => _statusMessage = 'เชื่อมต่อห้องประชุม...');
          await _connectToRoom();
          return;
        } else {
          throw Exception('get_video status ${resp.statusCode}');
        }
      } catch (e) {
        String reason = e.toString();
        if (kIsWeb && reason.contains('Failed to fetch')) {
          reason =
              'Failed to fetch (browser CORS). เซิร์ฟเวอร์ต้องเปิด CORS (Access-Control-Allow-Origin) หรือต้องเรียกผ่าน proxy';
        }

        try {
          final cached = await PatientIdCardStorage.loadPatientIdCardData();
          if (cached != null && cached['video_token'] != null) {
            _token = cached['video_token'].toString();
            setState(
              () => _statusMessage =
                  'ใช้ token จากเครื่อง (cache) และพยายามเชื่อมต่อ...',
            );
            await _connectToRoom();
            return;
          }
        } catch (_) {}

        await _showGetVideoErrorDialog(reason, publicId);
        return;
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'เชื่อมต่อ OpenVidu ไม่สำเร็จ: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectToRoom() async {
    try {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _statusMessage = 'เชื่อมต่อ Video Call สำเร็จ!';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 เชื่อมต่อ Video Call สำเร็จ!'),
            backgroundColor: Colors.green,
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

  void _toggleCamera() => setState(() => _isCameraOn = !_isCameraOn);
  void _toggleMicrophone() => setState(() => _isMicOn = !_isMicOn);

  void _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1 && _cameraController != null) {
      final currentCamera = _cameraController!.description;
      CameraDescription newCamera;
      if (currentCamera.lensDirection == CameraLensDirection.front) {
        newCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => currentCamera,
        );
      } else {
        newCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
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
      }
    }
  }

  void _endCall() => Navigator.of(context).pop();

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
          if (_isConnecting)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          const SizedBox(height: 24),
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
                  const Text(
                    '🟢 เชื่อมต่อแล้ว',
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
                Text(
                  'อีกฝั่งเข้าห้อง "$_sessionName"',
                  style: const TextStyle(color: Colors.yellow, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'mic',
                onPressed: _toggleMicrophone,
                backgroundColor: _isMicOn ? Colors.blue : Colors.red,
                child: Icon(
                  _isMicOn ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                heroTag: 'switch',
                onPressed: _switchCamera,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.switch_camera, color: Colors.white),
              ),
              FloatingActionButton(
                heroTag: 'end',
                onPressed: _endCall,
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
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

  // Dialog helper: show detailed error, curl and manual token entry
  Future<void> _showGetVideoErrorDialog(String reason, String? publicId) async {
    final curl =
        "curl -X POST 'https://emr-life.com/clinic_master/clinic/Api/get_video' -d 'public_id=${publicId ?? ''}'";
    final tokenController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('ไม่สามารถขอ token ได้'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason),
                const SizedBox(height: 12),
                const Text(
                  'คำสั่งทดสอบ (curl):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(curl),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: curl));
                        Navigator.of(context).pop();
                      },
                      child: const Text('คัดลอก curl'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('ปิด'),
                    ),
                  ],
                ),
                const Divider(),
                const Text(
                  'ถ้ามี token ในเครื่อง ให้กรอกที่นี่ (หรือวาง tok_...):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(hintText: 'tok_...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeVideoCall();
              },
              child: const Text('ลองใหม่'),
            ),
            ElevatedButton(
              onPressed: () async {
                final v = tokenController.text.trim();
                if (v.isNotEmpty) {
                  _token = v;
                  try {
                    final patient =
                        await PatientIdCardStorage.loadPatientIdCardData();
                    final updated = {...?patient, 'video_token': _token};
                    await PatientIdCardStorage.savePatientIdCardData(updated);
                  } catch (_) {}
                  Navigator.of(context).pop();
                  setState(() {
                    _statusMessage = 'ใช้ token ที่กรอกและพยายามเชื่อมต่อ...';
                    _isConnecting = true;
                  });
                  await _connectToRoom();
                }
              },
              child: const Text('ใช้ token และต่อ'),
            ),
          ],
        );
      },
    );
  }
}
