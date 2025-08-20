// lib/core/device/add_device/Beurer/beurer_tem_ft95.dart
import 'dart:async';
import 'dart:math';
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
  static final Guid _svcHealthThermometer = Guid('00001809-0000-1000-8000-00805f9b34fb');
  static final Guid _chrTemperatureMeasurement = Guid('00002A1C-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<double>.broadcast();
  Stream<double> get onTemperature => _controller.stream;

  BluetoothCharacteristic? _temperatureChar;

  /// Connect และ Discover Services
  Future<void> connect() async {
    await device.connect(autoConnect: false);
    final services = await device.discoverServices();

    for (final s in services) {
      if (s.uuid == _svcHealthThermometer) {
        for (final c in s.characteristics) {
          if (c.uuid == _chrTemperatureMeasurement) {
            _temperatureChar = c;
            await _temperatureChar!.setNotifyValue(true);
            _temperatureChar!.value.listen(_handleTemperature);
          }
        }
      }
    }
  }

  /// แปลงค่า Temperature จาก BLE packet
  void _handleTemperature(List<int> data) {
    if (data.isEmpty) return;

    final bytes = Uint8List.fromList(data);
    final buffer = ByteData.sublistView(bytes);

    // ตามมาตรฐาน Bluetooth Thermometer (IEEE-11073 32-bit float)
    // [0] Flags
    // [1..4] Temperature Measurement Value
    if (bytes.length >= 5) {
      int raw = buffer.getUint32(1, Endian.little);
      double tempC = _ieee11073FloatToDouble(raw);
      _controller.add(tempC);
    }
  }

  double _ieee11073FloatToDouble(int raw) {
    // IEEE-11073 float: 1 exponent (8-bit signed) + 24-bit mantissa
    int mantissa = raw & 0x00FFFFFF;
    int exponent = raw >> 24;

    if (mantissa >= 0x800000) {
      mantissa = -(0x1000000 - mantissa);
    }
    if (exponent >= 0x80) {
      exponent = -(0x100 - exponent);
    }
    return mantissa * (pow(10, exponent).toDouble());
  }

  Future<void> disconnect() async {
    await device.disconnect();
  }
}
