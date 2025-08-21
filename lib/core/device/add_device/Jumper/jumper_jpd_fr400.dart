// lib/core/device/add_device/Jumper/jumper_jpd_fr400.dart
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Jumper JPD-FR400 (Forehead Thermometer)
/// โฆษณามักแสดง service UUID = FFF0
/// ไฟล์นี้มี 3 อย่างให้ใช้:
/// 1) JumperFr400 (ตัวอ่าน) → Stream<double> เป็น °C
/// 2) Fr400Tile (ListTile ขนาดเล็กไว้แสดงบน device_page)
/// 3) Fr400Screen (หน้าเต็มไว้แสดงบน device_screen)
/// ─────────────────────────────────────────────────────────────────────────────
class JumperFr400 {
  JumperFr400({required this.device});
  final BluetoothDevice device;

  // Vendor service ที่พบบ่อยในตระกูล Jumper
  static final Guid _svcFff0 = Guid('0000fff0-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<double>.broadcast();
  Stream<double> get onTemperature => _controller.stream;

  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _sub;
  double? _lastOk;

  Future<void> start() async {
    // ถ้ายังไม่ต่อให้พยายามต่อ
    if (device.connectionState != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 8));
    }

    // ค้นหา service/characteristics
    final svcs = await device.discoverServices();

    // หา service FFF0 ก่อน (ถ้าไม่มีจะลองทุก service)
    Iterable<BluetoothService> candidates = svcs.where((s) => s.uuid == _svcFff0);
    if (candidates.isEmpty) candidates = svcs;

    // เลือก characteristic ตัวแรกที่ notify ได้
    for (final s in candidates) {
      final c = s.characteristics.firstWhere(
        (x) => x.properties.notify || x.properties.indicate,
        orElse: () => s.characteristics.isNotEmpty ? s.characteristics.first : throw StateError('FR400: no characteristic'),
      );
      _notifyChar = c;
      break;
    }

    final c = _notifyChar!;
    // เปิด notify ถ้ายังไม่ได้เปิด
    if (!c.isNotifying) {
      try {
        await c.setNotifyValue(true);
      } catch (_) {
        // บางรุ่นใช้ indicate แทน notify — ถ้าล้มเหลวก็ลองเฉยๆ (ผู้ผลิตบางรุ่นไม่ซีเรียส)
      }
    }

    _sub = c.onValueReceived.listen(_onData, onError: (e) {
      // เงียบไว้ แต่ไม่ทำให้แอปพัง
    });

    // บางรุ่นต้อง "เขี่ย" ให้ส่งค่า: ลองอ่านครั้งหนึ่ง
    try {
      await c.read();
    } catch (_) {}
  }

  void _onData(List<int> data) {
    if (data.isEmpty) return;
    final t = _tryParseTemperature(data);
    if (t == null) return;

    // กันดีด/เด้งจากเฟรมเสีย
    if (t < 30 || t > 44) return;

    // กันสเต็ปผิดปกติ (กระโดดเกิน 1.5°C ข้าม)
    if (_lastOk != null && (t - _lastOk!).abs() > 1.5) return;

    _lastOk = t;
    _controller.add(t);
  }

  /// พยายามถอดรูปแบบเฟรมที่พบได้บ่อยในตระกูล Jumper
  /// คืนค่าเป็น °C หรือ null ถ้าเดาไม่ได้
  double? _tryParseTemperature(List<int> bytes) {
    // 1) เฟรมขึ้นต้นด้วย FD FD FC <hi> <lo> 0D 0A  → (hi<<8|lo)/10
    if (bytes.length >= 6 &&
        bytes[0] == 0xFD &&
        bytes[1] == 0xFD &&
        bytes[2] == 0xFC) {
      final raw = (bytes[3] << 8) | bytes[4];
      final v = raw / 10.0;
      if (v > 25 && v < 45) return v;
      // ถ้าเหมือน °F ให้แปลง
      if (v >= 90 && v <= 113) return _f2c(v);
    }

    // 2) จับตัวเลข ASCII เช่น "36.7C", "T=36.5" เป็นต้น
    try {
      final s = String.fromCharCodes(bytes);
      final match = RegExp(r'(-?\d{2}\.\d)').firstMatch(s);
      if (match != null) {
        final v = double.parse(match.group(0)!);
        if (s.contains('F') && !s.contains('C')) return _f2c(v);
        return v;
      }
    } catch (_) {}

    // 3) สแกนทุกคู่ไบต์เป็น 16-bit /10 → 30..44°C
    for (int i = 0; i + 1 < bytes.length; i++) {
      final raw = (bytes[i] << 8) | bytes[i + 1];
      final v = raw / 10.0;
      if (v >= 30 && v <= 44) return v;
      if (v >= 90 && v <= 113) return _f2c(v);
    }

    // 4) สแกนเลขเต็ม /100
    for (int i = 0; i + 1 < bytes.length; i++) {
      final raw = (bytes[i] << 8) | bytes[i + 1];
      final v = raw / 100.0;
      if (v >= 30 && v <= 44) return v;
      if (v >= 90 && v <= 113) return _f2c(v);
    }

    return null;
  }

  double _f2c(double f) => (f - 32.0) / 1.8;

  Future<void> stop() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;

    try {
      if (_notifyChar != null && _notifyChar!.isNotifying) {
        await _notifyChar!.setNotifyValue(false);
      }
    } catch (_) {}

    _notifyChar = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// วิดเจ็ตขนาดเล็กไว้ติดใน device_page
/// ─────────────────────────────────────────────────────────────────────────────
class Fr400Tile extends StatefulWidget {
  const Fr400Tile({Key? key, required this.device, this.title}) : super(key: key);
  final BluetoothDevice device;
  final String? title;

  @override
  State<Fr400Tile> createState() => _Fr400TileState();
}

class _Fr400TileState extends State<Fr400Tile> {
  late final JumperFr400 _reader = JumperFr400(device: widget.device);
  double? _temp;
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _reader.start();
    _sub = _reader.onTemperature.listen((v) {
      if (mounted) setState(() => _temp = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.title ?? (widget.device.platformName.isNotEmpty ? widget.device.platformName : 'Jumper FR400');
    return ListTile(
      leading: const Icon(Icons.thermostat),
      title: Text(name),
      subtitle: Text(_temp == null ? 'กำลังรออุณหภูมิ…' : '${_temp!.toStringAsFixed(1)} °C'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => Fr400Screen(device: widget.device),
        ));
      },
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// หน้าเต็มสำหรับ device_screen
/// ─────────────────────────────────────────────────────────────────────────────
class Fr400Screen extends StatefulWidget {
  const Fr400Screen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  State<Fr400Screen> createState() => _Fr400ScreenState();
}

class _Fr400ScreenState extends State<Fr400Screen> {
  late final JumperFr400 _reader = JumperFr400(device: widget.device);
  StreamSubscription<double>? _sub;
  double? _temp;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _reader.start();
    _sub = _reader.onTemperature.listen((v) {
      if (mounted) setState(() => _temp = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : 'Jumper JPD-FR400';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: _temp == null
            ? const Text('กำลังรออุณหภูมิ…', style: TextStyle(fontSize: 22))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.thermostat, size: 64),
                  const SizedBox(height: 12),
                  Text('${_temp!.toStringAsFixed(1)} °C',
                      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Forehead IR • Instant', style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
      ),
    );
  }
}
