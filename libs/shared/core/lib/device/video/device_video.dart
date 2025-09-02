import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// แสดงภาพ/วิดีโอของอุปกรณ์จาก assets
/// - ถ้าไฟล์ลงท้าย .mp4 จะเล่นวิดีโอ (loop + mute + autoplay)
/// - ถ้าไม่ใช่ .mp4 จะใช้ Image.asset ปกติ
class DeviceVideo extends StatefulWidget {
  const DeviceVideo({
    super.key,
    required this.assetPath,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.autoplay = true,
    this.looping = true,
    this.muted = true,
  });

  final String assetPath;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool autoplay;
  final bool looping;
  final bool muted;

  @override
  State<DeviceVideo> createState() => _DeviceVideoState();
}

class _DeviceVideoState extends State<DeviceVideo> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _error = false;

  bool get _isVideo => widget.assetPath.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant DeviceVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _disposeController();
      _init();
    }
  }

  void _init() {
    if (!_isVideo) return;
    _c = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(widget.looping)
      ..setVolume(widget.muted ? 0.0 : 1.0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        if (widget.autoplay) _c?.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _error = true);
      });
  }

  void _disposeController() {
    _c?.dispose();
    _c = null;
    _ready = false;
    _error = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.borderRadius ?? BorderRadius.circular(24);

    Widget child;
    if (_isVideo) {
      if (_error) {
        child = const _PlaceholderBox();
      } else if (_ready && _c != null) {
        // ขยายให้เต็มกรอบ โดยรักษาอัตราส่วน
        child = FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _c!.value.size.width,
            height: _c!.value.size.height,
            child: VideoPlayer(_c!),
          ),
        );
      } else {
        child = const _PlaceholderBox(); // ระหว่างโหลด
      }
    } else {
      child = Image.asset(
        widget.assetPath,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => const _PlaceholderBox(),
      );
    }

    return ClipRRect(borderRadius: border, child: child);
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F6F8),
      alignment: Alignment.center,
      child: const Icon(Icons.devices_other, size: 64, color: Colors.black26),
    );
  }
}
