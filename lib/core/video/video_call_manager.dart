// lib/core/video/video_call_manager.dart
import 'package:flutter/foundation.dart';
import 'package:smarttelemed_v4/core/video/openvidu_service.dart';
import 'package:smarttelemed_v4/core/video/video_config.dart';
import 'package:smarttelemed_v4/core/video/video_utils.dart';

enum VideoCallState { idle, connecting, connected, disconnected, error }

class VideoCallManager extends ChangeNotifier {
  static final VideoCallManager _instance = VideoCallManager._internal();
  factory VideoCallManager() => _instance;
  VideoCallManager._internal();

  VideoCallState _state = VideoCallState.idle;
  String? _sessionId;
  String? _token;
  String? _participantName;
  bool _audioEnabled = VideoConfig.defaultAudioEnabled;
  bool _videoEnabled = VideoConfig.defaultVideoEnabled;
  String? _errorMessage;

  // Getters
  VideoCallState get state => _state;
  String? get sessionId => _sessionId;
  String? get token => _token;
  String? get participantName => _participantName;
  bool get audioEnabled => _audioEnabled;
  bool get videoEnabled => _videoEnabled;
  String? get errorMessage => _errorMessage;

  // เริ่มต้น Video Call
  Future<bool> startCall({String? participantName}) async {
    try {
      _setState(VideoCallState.connecting);

      // ตรวจสอบการเชื่อมต่อ
      final isConnected = await OpenViduService.checkConnection();
      if (!isConnected) {
        _setError(VideoConfig.connectionErrorMessage);
        return false;
      }

      // สร้าง session
      _sessionId = await OpenViduService.createSession();

      // สร้าง token
      _participantName =
          participantName ?? VideoUtils.generateParticipantName();
      _token = await OpenViduService.generateToken(
        sessionId: _sessionId!,
        participantName: _participantName,
      );

      _setState(VideoCallState.connected);
      return true;
    } catch (e) {
      _setError('${VideoConfig.generalErrorMessage}: $e');
      return false;
    }
  }

  // สิ้นสุด Video Call
  void endCall() {
    _sessionId = null;
    _token = null;
    _participantName = null;
    _errorMessage = null;
    _setState(VideoCallState.disconnected);

    // Reset to idle after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (_state == VideoCallState.disconnected) {
        _setState(VideoCallState.idle);
      }
    });
  }

  // สลับไมค์
  void toggleAudio() {
    _audioEnabled = !_audioEnabled;
    notifyListeners();
  }

  // สลับกล้อง
  void toggleVideo() {
    _videoEnabled = !_videoEnabled;
    notifyListeners();
  }

  // รีเซ็ตสถานะ
  void reset() {
    _state = VideoCallState.idle;
    _sessionId = null;
    _token = null;
    _participantName = null;
    _audioEnabled = VideoConfig.defaultAudioEnabled;
    _videoEnabled = VideoConfig.defaultVideoEnabled;
    _errorMessage = null;
    notifyListeners();
  }

  // สร้าง WebView URL
  String? getWebViewUrl() {
    if (_token == null || _participantName == null) return null;

    return OpenViduService.buildWebViewUrl(
      token: _token!,
      participantName: _participantName!,
      audioEnabled: _audioEnabled,
      videoEnabled: _videoEnabled,
    );
  }

  // Private methods
  void _setState(VideoCallState newState) {
    _state = newState;
    if (newState != VideoCallState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(VideoCallState.error);
  }
}
