// lib/core/device/add_device/ua_651ble.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

class BpReading {
  final double systolic;
  final double diastolic;
  final double map;
  final double? pulse;
  final DateTime? timestamp;
  const BpReading({required this.systolic, required this.diastolic, required this.map, this.pulse, this.timestamp});
  @override
  String toString() => 'BP(sys:$systolic, dia:$diastolic, map:$map, pulse:${pulse ?? '-'}, time:${timestamp ?? '-'})';
}

class AdUa651Ble {
  final BluetoothDevice device;
  AdUa651Ble({required this.device});

  static final Guid _svcBp = Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid _chrBp = Guid('00002a35-0000-1000-8000-00805f9b34fb');

  final _controller = StreamController<BpReading>.broadcast();
  StreamSubscription<List<int>>? _valueSub;

  Future<Stream<BpReading>> parse() async {
    await _ensureConnected();

    final services = await device.discoverServices();
    final svc = services.firstWhere(
      (s) => s.uuid == _svcBp,
      orElse: () => throw Exception('ไม่พบ Blood Pressure service (0x1810)'),
    );
    final chr = svc.characteristics.firstWhere(
      (c) => c.uuid == _chrBp,
      orElse: () => throw Exception('ไม่พบ Blood Pressure Measurement (0x2A35)'),
    );

    await chr.setNotifyValue(true);

    await _valueSub?.cancel();
    _valueSub = chr.lastValueStream.listen((data) {
      final reading = _parseBpMeasurement(data);
      if (reading != null) _controller.add(reading);
    });

    try { await chr.read(); } catch (_) {}
    return _controller.stream;
  }

  Future<void> dispose() async {
    await _valueSub?.cancel();
    await _controller.close();
  }

  // ---- เชื่อมต่อให้เสถียร และไม่ชน state ----
  Future<void> _ensureConnected() async {
    // หยุดสแกนเพื่อกันชน GATT
    try { await FlutterBluePlus.stopScan(); } catch (_) {}

    var state = await device.connectionState.first;

    if (state == BluetoothConnectionState.connected) {
      return;
    }

    if (state == BluetoothConnectionState.connecting) {
      // รอจนกว่าจะ connected หรือหลุด
      state = await device.connectionState
          .where((s) =>
              s == BluetoothConnectionState.connected ||
              s == BluetoothConnectionState.disconnected)
          .first
          .timeout(const Duration(seconds: 12), onTimeout: () => BluetoothConnectionState.disconnected);
      if (state == BluetoothConnectionState.connected) return;
    }

    // เชื่อมต่อใหม่
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
    await device.connectionState
        .where((s) =>
            s == BluetoothConnectionState.connected ||
            s == BluetoothConnectionState.disconnected)
        .first
        .timeout(const Duration(seconds: 12));
  }

  // ---------- Parser 0x2A35 ----------
  BpReading? _parseBpMeasurement(List<int> data) {
    if (data.isEmpty) return null;
    int i = 0;
    final flags = data[i++];

    final isKpa = (flags & 0x01) != 0;
    if (data.length < i + 6) return null;

    final systolic  = _decodeSfloat16(data[i], data[i + 1]); i += 2;
    final diastolic = _decodeSfloat16(data[i], data[i + 1]); i += 2;
    final map       = _decodeSfloat16(data[i], data[i + 1]); i += 2;

    DateTime? ts;
    if ((flags & 0x02) != 0 && data.length >= i + 7) {
      final year = data[i] | (data[i + 1] << 8);
      final month = data[i + 2];
      final day = data[i + 3];
      final hour = data[i + 4];
      final minute = data[i + 5];
      final second = data[i + 6];
      i += 7;
      ts = DateTime.tryParse('${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}');
    }

    double? pulse;
    if ((flags & 0x04) != 0 && data.length >= i + 2) {
      pulse = _decodeSfloat16(data[i], data[i + 1]); i += 2;
    }

    if (systolic == null || diastolic == null || map == null) return null;

    const kPa2mmHg = 7.50062;
    final sVal = isKpa ? (systolic * kPa2mmHg) : systolic;
    final dVal = isKpa ? (diastolic * kPa2mmHg) : diastolic;
    final mVal = isKpa ? (map * kPa2mmHg) : map;

    return BpReading(systolic: sVal, diastolic: dVal, map: mVal, pulse: pulse, timestamp: ts);
  }

  double? _decodeSfloat16(int b0, int b1) {
    final raw = (b1 << 8) | (b0 & 0xFF);
    if (raw == 0x07FF || raw == 0x0800 || raw == 0x07FE) return null;
    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x0008) != 0) exponent |= ~0x000F;
    return mantissa * math.pow(10.0, exponent).toDouble();
  }
}