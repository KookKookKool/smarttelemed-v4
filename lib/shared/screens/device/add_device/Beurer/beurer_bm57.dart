// lib/core/device/add_device/Beurer/beurer_bm57.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

/// Beurer BM57 - Blood Pressure Monitor
/// ใช้ Blood Pressure Service (0x1810)
/// - Blood Pressure Measurement (0x2A35) → Indicate
/// - Intermediate Cuff Pressure (0x2A36) → Notify (ระหว่างวัด)
/// - Blood Pressure Feature (0x2A49) → Read (ความสามารถของอุปกรณ์)
/// - Device Information (0x180A) → ข้อมูลรุ่น/ซีเรียล/เฟิร์มแวร์ ฯลฯ
///
/// ส่งออกเป็น Stream<Map<String, String>>
/// ตัวอย่าง: { sys: "122", dia: "78", map: "96", pul: "72", unit: "mmHg", ts: "2025-08-21 11:14:08" }
class BeurerBm57 {
  BeurerBm57({required this.device});
  final BluetoothDevice device;

  // --------- UUIDs ---------
  // Blood Pressure (standard)
  static final Guid _svcBloodPressure =
      Guid('00001810-0000-1000-8000-00805f9b34fb');
  static final Guid _chrBpMeasurement =
      Guid('00002A35-0000-1000-8000-00805f9b34fb'); // indicate
  static final Guid _chrIntermediateCuff =
      Guid('00002A36-0000-1000-8000-00805f9b34fb'); // notify
  // static final Guid _chrBpFeature =
  //     Guid('00002A49-0000-1000-8000-00805f9b34fb'); // read

  // Device Information (standard)
  static final Guid _svcDeviceInfo =
      Guid('0000180A-0000-1000-8000-00805f9b34fb');
  static final Guid _chrModelNumber =
      Guid('00002A24-0000-1000-8000-00805f9b34fb');
  static final Guid _chrSerialNumber =
      Guid('00002A25-0000-1000-8000-00805f9b34fb');
  static final Guid _chrFirmwareRev =
      Guid('00002A26-0000-1000-8000-00805f9b34fb');
  static final Guid _chrHardwareRev =
      Guid('00002A27-0000-1000-8000-00805f9b34fb');
  static final Guid _chrSoftwareRev =
      Guid('00002A28-0000-1000-8000-00805f9b34fb');
  static final Guid _chrManufacturer =
      Guid('00002A29-0000-1000-8000-00805f9b34fb');
  static final Guid _chrSystemId =
      Guid('00002A23-0000-1000-8000-00805f9b34fb');
  static final Guid _chrRegCert =
      Guid('00002A2A-0000-1000-8000-00805f9b34fb');
  static final Guid _chrPnpId =
      Guid('00002A50-0000-1000-8000-00805f9b34fb');

  /// Public getter เพื่อให้อ้างอิง UUID service จากไฟล์อื่น (เช่น device_page.dart)
  static Guid get bloodPressureService => _svcBloodPressure;

  // --------- State ---------
  BluetoothCharacteristic? _bpMeasChar;
  BluetoothCharacteristic? _bpInterChar;

  final _bpController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get onBloodPressure => _bpController.stream;

  // --------- Lifecycle ---------
  /// ค้นหา service/characteristic และ subscribe
  Future<void> start() async {
    final services = await device.discoverServices();

    // หา Blood Pressure service
    final bpSvc = services.firstWhere(
      (s) => s.uuid == _svcBloodPressure,
      orElse: () =>
          throw Exception('Blood Pressure service (0x1810) not found'),
    );

    // หา Measurement (บังคับต้องมี)
    _bpMeasChar = bpSvc.characteristics.firstWhere(
      (c) => c.uuid == _chrBpMeasurement,
      orElse: () => throw Exception('BP Measurement (0x2A35) not found'),
    );

    // หา Intermediate (บางรุ่นอาจไม่มี → ตั้งเป็น null ได้)
    final matchInter = bpSvc.characteristics
        .where((c) => c.uuid == _chrIntermediateCuff)
        .toList();
    _bpInterChar = matchInter.isNotEmpty ? matchInter.first : null;

    // เปิด listen Measurement (Indicate)
    await _bpMeasChar!.setNotifyValue(true);
    _bpMeasChar!.lastValueStream.listen(
      _handleMeasurement,
      onError: (e, st) {
        if (kDebugMode) print('BM57 meas err: $e');
      },
    );

    // เปิด listen Intermediate Cuff (Notify) ถ้ามี
    if (_bpInterChar != null) {
      await _bpInterChar!.setNotifyValue(true);
      _bpInterChar!.lastValueStream.listen(
        _handleIntermediate,
        onError: (e, st) {
          if (kDebugMode) print('BM57 inter err: $e');
        },
      );
    }
  }

  Future<void> stop() async {
    try {
      if (_bpMeasChar != null) {
        await _bpMeasChar!.setNotifyValue(false);
      }
      if (_bpInterChar != null) {
        await _bpInterChar!.setNotifyValue(false);
      }
    } catch (_) {}
    await _bpController.close();
  }

  /// อ่าน Device Information ทั้งชุด
  Future<Map<String, String>> readDeviceInfo() async {
    final out = <String, String>{};
    final services = await device.discoverServices();
    final dis = services.firstWhere(
      (s) => s.uuid == _svcDeviceInfo,
      orElse: () => throw Exception('Device Information (0x180A) not found'),
    );

    Future<void> rd(Guid g, String key) async {
      try {
        final c = dis.characteristics.firstWhere((c) => c.uuid == g);
        final v = await c.read();
        out[key] = _tryUtf8(v);
      } catch (_) {}
    }

    await rd(_chrModelNumber, 'model');         // BM57
    await rd(_chrSerialNumber, 'serial');       // B801A1
    await rd(_chrFirmwareRev, 'firmware');      // Nov 19 2015
    await rd(_chrHardwareRev, 'hardware');      // 0.1
    await rd(_chrSoftwareRev, 'software');      // 0.1
    await rd(_chrManufacturer, 'manufacturer'); // beurer
    await rd(_chrSystemId, 'system_id');
    await rd(_chrRegCert, 'regulatory');
    await rd(_chrPnpId, 'pnp_id');
    return out;
  }

  // --------- Parsers ---------
  void _handleMeasurement(List<int> data) {
    final parsed = _parseBpMeasurement(data);
    if (parsed != null) _bpController.add(parsed);
  }

  void _handleIntermediate(List<int> data) {
    // แสดงเป็นค่า cuff ชั่วคราว ระหว่างวัด
    try {
      final bytes = Uint8List.fromList(data);
      final flags = bytes[0];
      final unitIsKpa = (flags & 0x01) != 0; // bit0=1 -> kPa, 0 -> mmHg
      final cuff = _readSfloat(bytes, 1);
      _bpController.add({
        'cuff': cuff.toStringAsFixed(0),
        'unit': unitIsKpa ? 'kPa' : 'mmHg',
        'ts': DateTime.now().toString().split('.').first,
      });
    } catch (_) {
      // ignore parse error
    }
  }

  Map<String, String>? _parseBpMeasurement(List<int> data) {
    try {
      final bytes = Uint8List.fromList(data);
      int idx = 0;
      final flags = bytes[idx++];

      final unitIsKpa = (flags & 0x01) != 0; // 0: mmHg, 1: kPa
      final systolic = _readSfloat(bytes, idx); idx += 2;
      final diastolic = _readSfloat(bytes, idx); idx += 2;
      final meanAp = _readSfloat(bytes, idx); idx += 2;

      // optional fields
      final hasTimestamp = (flags & 0x02) != 0;
      if (hasTimestamp) idx += 7;

      double? pulse;
      final hasPulse = (flags & 0x04) != 0;
      if (hasPulse) {
        pulse = _readSfloat(bytes, idx);
        idx += 2;
      }

      String unit = unitIsKpa ? 'kPa' : 'mmHg';

      // แปลง kPa -> mmHg ถ้าจำเป็น (* 7.50062)
      double s = systolic, d = diastolic, m = meanAp;
      if (unitIsKpa) {
        s = systolic * 7.50062;
        d = diastolic * 7.50062;
        m = meanAp * 7.50062;
        unit = 'mmHg';
      }

      return {
        'sys': s.isFinite ? s.toStringAsFixed(0) : '',
        'dia': d.isFinite ? d.toStringAsFixed(0) : '',
        // 'map': m.isFinite ? m.toStringAsFixed(0) : '',
        if (pulse != null) 'pul': pulse.toStringAsFixed(0),
        'unit': unit,
        'ts': DateTime.now().toString().split('.').first,
      };
    } catch (e) {
      if (kDebugMode) print('BM57 parse error: $e');
      return null;
    }
  }

  /// อ่าน IEEE-11073 16-bit SFLOAT (mantissa 12b + exponent 4b)
  double _readSfloat(Uint8List b, int i) {
    final raw = (b[i] & 0xFF) | ((b[i + 1] & 0xFF) << 8);

    // Special NaN case
    if (raw == 0x07FF) return double.nan;

    // mantissa (12-bit signed)
    int mantissa = raw & 0x0FFF;
    if ((mantissa & 0x0800) != 0) {
      mantissa = -((0x0FFF + 1) - mantissa);
    }

    // exponent (4-bit signed)
    int exponent = (raw >> 12) & 0x000F;
    if ((exponent & 0x0008) != 0) {
      exponent = -((0x000F + 1) - exponent);
    }

    return mantissa * _pow10(exponent);
  }

  /// pow10 ที่กัน index หลุดช่วง [-8..7] และ fallback เป็น math.pow
  double _pow10(int e) {
    const table = <double>[
      1e-8, 1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1,
      1, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7,
    ];
    final idx = e + 8;
    if (idx >= 0 && idx < table.length) {
      return table[idx];
    }
    // fallback ถ้า exponent เกินช่วงตาราง
    return math.pow(10.0, e).toDouble();
  }

  String _tryUtf8(List<int> v) {
    try {
      return String.fromCharCodes(v).trim();
    } catch (_) {
      return v.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    }
  }
}
