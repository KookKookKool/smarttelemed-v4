// lib/core/device/add_device/Beurer/beurer_tem_ft95.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

/// Beurer FT95 - Thermometer
/// อ่านค่า Temperature ผ่าน Service 0x1809 / Characteristic 0x2A1C
/// ส่งออกเป็น Stream<double> หน่วย °C
class BeurerFt95 {
  BeurerFt95({required this.device});
  final BluetoothDevice device;

  // UUIDs
  static final Guid _svcHealthThermometer =
      Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid _chrTemperatureMeasurement =
      Guid('00002A1C-0000-1000-8000-00805f9b34fb');

  // สตรีมยิงค่า °C ออกไปให้ UI
  final _controller = StreamController<double>.broadcast();
  Stream<double> get onTemperature => _controller.stream;

  BluetoothCharacteristic? _temperatureChar;

  // เก็บค่าล่าสุดไว้เสมอ (กันค่าหายตอน disconnect)
  double? _lastTempC;

  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _valSub;

  /// เชื่อมต่อ + discover + subscribe 0x2A1C
  Future<void> connect() async {
    // กัน connect ซ้อน
    var st = await device.connectionState.first;
    if (st == BluetoothConnectionState.disconnected) {
      await device.connect(autoConnect: false);
      // รอจน connected
      st = await device.connectionState
          .where((s) =>
              s == BluetoothConnectionState.connected ||
              s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 12));
      if (st != BluetoothConnectionState.connected) {
        throw 'เชื่อมต่อ FT95 ไม่สำเร็จ';
      }
    }

    // Discover services
    final services = await device.discoverServices();

    BluetoothCharacteristic? tempChar;
    for (final s in services) {
      if (s.uuid == _svcHealthThermometer) {
        for (final c in s.characteristics) {
          if (c.uuid == _chrTemperatureMeasurement) {
            tempChar = c;
            break;
          }
        }
      }
      if (tempChar != null) break;
    }
    if (tempChar == null) {
      throw 'ไม่พบ Temperature Measurement (0x2A1C)';
    }
    _temperatureChar = tempChar;

    // Subscribe notify
    await _temperatureChar!.setNotifyValue(true);
    await _valSub?.cancel();
    _valSub = _temperatureChar!.value.listen(_handleTemperature, onError: (e) {
      if (!_controller.isClosed) {
        // ส่ง error เป็น optional: ที่นี่เลือกไม่ propagate error ไปสตรีม
      }
    });

    // หาก disconnect ให้ยิงค่าล่าสุดซ้ำเพื่อค้างบน UI
    await _connSub?.cancel();
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected && _lastTempC != null) {
        scheduleMicrotask(() {
          if (!_controller.isClosed) {
            _controller.add(_lastTempC!);
          }
        });
      }
    });
  }

  /// แปลงค่า Temperature จาก BLE packet ของ 0x2A1C
  /// รูปแบบ:
  /// [0] Flags (bit0: 0=°C, 1=°F)
  /// [1..4] Temperature (IEEE‑11073 32-bit float, little-endian)
  /// (timestamp/type ถ้ามีจะตามหลัง แต่เราไม่ใช้)
  void _handleTemperature(List<int> data) {
    if (data.isEmpty) return;

    final bytes = Uint8List.fromList(data);
    if (bytes.length < 5) return;

    final flags = bytes[0];
    final isFahrenheit = (flags & 0x01) != 0;

    final buffer = ByteData.sublistView(bytes);
    final raw = buffer.getUint32(1, Endian.little);
    var value = _ieee11073FloatToDouble(raw);

    // ถ้าเป็น °F ให้แปลงเป็น °C
    final tempC = isFahrenheit ? ((value - 32.0) / 1.8) : value;

    _lastTempC = tempC;
    if (!_controller.isClosed) {
      _controller.add(tempC);
    }
  }

  /// แปลง IEEE‑11073 32-bit float (mantissa 24-bit + exponent 8-bit signed)
  double _ieee11073FloatToDouble(int raw) {
    int mantissa = raw & 0x00FFFFFF;
    int exponent = raw >> 24;

    // sign-extend
    if (mantissa >= 0x800000) {
      mantissa = -(0x1000000 - mantissa);
    }
    if (exponent >= 0x80) {
      exponent = -(0x100 - exponent);
    }

    return mantissa * math.pow(10, exponent).toDouble();
  }

  /// คืนค่าล่าสุดที่จำไว้ (อาจเป็น null ถ้ายังไม่เคยอ่าน)
  double? get lastTempC => _lastTempC;

  /// ตัดการเชื่อมต่อ (ไม่ปิด _controller เพื่อค้างค่าเดิมบน UI)
  Future<void> disconnect() async {
    await _valSub?.cancel();
    await _connSub?.cancel();
    try {
      await device.disconnect();
    } catch (_) {}
  }

  /// หากไม่ได้ใช้พาร์เซอร์นี้แล้วจริง ๆ ค่อย dispose ให้ครบ
  Future<void> dispose() async {
    await _valSub?.cancel();
    await _connSub?.cancel();
    try {
      await device.disconnect();
    } catch (_) {}
    await _controller.close();
  }
}
