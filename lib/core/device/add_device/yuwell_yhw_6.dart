// lib/core/device/add_device/yuwell_yhw_6.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';


/// Health Thermometer Service (0x1809)
/// Temperature Measurement (0x2A1C)
/// คืน Stream<double> เป็น °C
class YuwellYhw6 {
  YuwellYhw6({required this.device});
  final BluetoothDevice device;

  static final Guid _svcThermo = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid _chrTemp   = Guid('00002a1c-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<double>.broadcast();
  StreamSubscription<List<int>>? _sub;

  Future<Stream<double>> parse() async {
    final st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(timeout: const Duration(seconds: 10));
    }

    final services = await device.discoverServices();
    final svc = services.firstWhere(
      (s) => s.uuid == _svcThermo,
      orElse: () => throw Exception('ไม่พบ Health Thermometer service (0x1809)'),
    );
    final chr = svc.characteristics.firstWhere(
      (c) => c.uuid == _chrTemp,
      orElse: () => throw Exception('ไม่พบ Temperature Measurement (0x2A1C)'),
    );

    await chr.setNotifyValue(true);

    await _sub?.cancel();
    _sub = chr.lastValueStream.listen((data) {
      final celsius = _parse2A1CToCelsius(data);
      if (celsius != null) {
        _controller.add(celsius);
      }
    });

    try { await chr.read(); } catch (_) {}
    return _controller.stream;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  /// Parse 0x2A1C → °C
  ///
  /// flags (byte0):
  ///  bit0: 0=Celsius, 1=Fahrenheit
  ///  bit1: Time Stamp present (7 bytes)
  ///  bit2: Temp Type present (1 byte)
  double? _parse2A1CToCelsius(List<int> data) {
    if (data.isEmpty) return null;

    int i = 0;
    final flags = data[i++];
    final isFahrenheit = (flags & 0x01) != 0;
    final hasTimestamp = (flags & 0x02) != 0;
    final hasType      = (flags & 0x04) != 0;

    // ตามสเปค 2A1C ใช้ FLOAT (32-bit, IEEE-11073)
    double? temp = _decodeFloat32_11073(
      data.length >= i + 4 ? data[i] : null,
      data.length >= i + 4 ? data[i + 1] : null,
      data.length >= i + 4 ? data[i + 2] : null,
      data.length >= i + 4 ? data[i + 3] : null,
    );
    if (temp != null) i += 4;

    // บางอุปกรณ์ consumer-grade อาจส่งเป็น SFLOAT16 (ผิดสเปคแต่พบได้)
    if (temp == null && data.length >= i + 2) {
      temp = _decodeSfloat16(data[i], data[i + 1]);
      i += 2;
    }

    // ข้าม timestamp/type ถ้ามี (ไม่ใช้ในการคำนวณ)
    if (hasTimestamp && data.length >= i + 7) i += 7;
    if (hasType      && data.length >= i + 1) i += 1;

    if (temp == null) return null;

    // แปลง F → C ถ้าจำเป็น
    final celsius = isFahrenheit ? ((temp - 32.0) * (5.0 / 9.0)) : temp;

    // กรองค่าหลุดโลก
    if (celsius.isNaN || celsius.isInfinite) return null;
    if (celsius < 10.0 || celsius > 50.0) {
      // อุณหภูมิร่างกายปกติควรอยู่ ~30–45°C (กันค่างง ๆ เช่น -500)
      return null;
    }
    return celsius;
  }

  /// IEEE-11073 FLOAT 32-bit (mantissa 24-bit signed + exponent 8-bit signed, little-endian)
  /// Layout (LE): [b0]=mantissa LSB, [b1]=mantissa, [b2]=mantissa MSB, [b3]=exponent
  double? _decodeFloat32_11073(int? b0, int? b1, int? b2, int? b3) {
    if (b0 == null || b1 == null || b2 == null || b3 == null) return null;
    int mantissa = (b0 & 0xFF) | ((b1 & 0xFF) << 8) | ((b2 & 0xFF) << 16);
    int exponent = (b3 & 0xFF);

    // sign-extend mantissa (24-bit) และ exponent (8-bit)
    if ((mantissa & 0x00800000) != 0) mantissa |= ~0x00FFFFFF;
    if ((exponent & 0x80) != 0) exponent |= ~0xFF;

    // ค่าพิเศษตามสเปค (NaN/NRes/±INF) — ทิ้ง
    if (mantissa == 0x007FFFFE || mantissa == 0x007FFFFF) return null;

    final val = mantissa * math.pow(10.0, exponent);
    return val.toDouble();
  }

  /// IEEE-11073 16-bit SFLOAT (fallback)
  double? _decodeSfloat16(int b0, int b1) {
    int raw = (b1 << 8) | (b0 & 0xFF);
    if (raw == 0x07FF || raw == 0x0800 || raw == 0x07FE) return null; // NaN/±INF
    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x0008) != 0) exponent |= ~0x000F;
    return mantissa * math.pow(10.0, exponent).toDouble();
  }
}
