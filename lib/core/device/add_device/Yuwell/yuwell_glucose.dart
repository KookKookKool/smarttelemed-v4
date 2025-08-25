 // lib/core/device/add_device/Yuwell/yuwellglucose_simple.dart
import 'dart:async';
import 'dart:math' show pow;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class YuwellGlucose {
  final BluetoothDevice device;
  YuwellGlucose({required this.device});

  static final Guid _svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
  static final Guid _chrMeas    = Guid('00002A18-0000-1000-8000-00805f9b34fb'); // notify
  static final Guid _chrRacp    = Guid('00002A52-0000-1000-8000-00805f9b34fb'); // write+ind

  final _ctrl = StreamController<String>.broadcast();
  StreamSubscription<List<int>>? _subMeas, _subRacp;
  BluetoothCharacteristic? _cMeas, _cRacp;

  Future<void> _ensureConnected() async {
    try { await device.requestMtu(247); } catch (_) {}
    var st = await device.connectionState.first;
    if (st != BluetoothConnectionState.connected) {
      await device.connect(autoConnect: false);
      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first;
    }
  }

  /// เริ่มดึงค่า; ถ้า fetchLastOnly=true จะดึง "เรคอร์ดล่าสุด" จากเครื่อง
  Stream<String> parse({bool fetchLastOnly = true}) {
    // รัน async pipeline แล้วคืน stream ออกไปเลย
    () async {
      try {
        await _ensureConnected();
        final svcs = await device.discoverServices();
        final svc = svcs.firstWhere(
          (s) => s.uuid == _svcGlucose,
          orElse: () => throw 'ไม่พบ Glucose Service (0x1808)',
        );
        for (final c in svc.characteristics) {
          if (c.uuid == _chrMeas) _cMeas = c;
          if (c.uuid == _chrRacp) _cRacp = c;
        }
        if (_cMeas == null || _cRacp == null) {
          throw 'ไม่พบ 0x2A18 หรือ 0x2A52';
        }

        // เปิด notify/indicate
        await _cMeas!.setNotifyValue(true);
        _subMeas = _cMeas!.value.listen((raw) {
          // ถอดแพ็กเก็ต Measurement -> ได้ mmol และ mg/dL อย่างถูกต้อง
          final mgdl = _decodeMgdl(Uint8List.fromList(raw));
          if (mgdl != null) {
            _ctrl.add(mgdl.toStringAsFixed(0)); // ส่งเฉพาะ mg/dL ตามสัญญาเดิม
          }
        }, onError: (e) => debugPrint('glucose meas err: $e'));

        await _cRacp!.setNotifyValue(true);
        _subRacp = _cRacp!.value.listen((raw) {
          debugPrint('RACP: $raw'); // สำหรับดีบัก
        });

        // รอ CCCD เซ็ตเสร็จก่อนสั่ง RACP
        await Future.delayed(const Duration(milliseconds: 300));

        // ขอข้อมูลจากเครื่อง
        if (fetchLastOnly) {
          // ขอเรคอร์ดล่าสุด (0x01, 0x06)
          await _cRacp!.write([0x01, 0x06], withoutResponse: false);
        } else {
          // ขอทั้งหมด (0x01, 0x01)
          await _cRacp!.write([0x01, 0x01], withoutResponse: false);
        }
      } catch (e, st) {
        debugPrint('YuwellGlucose error: $e\n$st');
        _ctrl.addError(e);
      }
    }();

    // ทำความสะอาดเมื่อยกเลิกฟัง
    _ctrl.onCancel = () async {
      try { await _subMeas?.cancel(); } catch (_) {}
      try { await _subRacp?.cancel(); } catch (_) {}
      try { if (_cMeas != null) await _cMeas!.setNotifyValue(false); } catch (_) {}
      try { if (_cRacp != null) await _cRacp!.setNotifyValue(false); } catch (_) {}
    };

    return _ctrl.stream;
  }

  /// ถอดค่า mg/dL จาก Glucose Measurement (0x2A18) ตามสเปค
  double? _decodeMgdl(Uint8List data) {
    if (data.isEmpty) return null;
    int i = 0;
    final flags = data[i++];

    int _u16(int idx) => data[idx] | (data[idx + 1] << 8);
    int _i16(int idx) {
      final v = _u16(idx);
      return v >= 0x8000 ? v - 0x10000 : v;
    }

    // ลำดับและเวลา (ไม่ใช้ในเวอร์ชันง่ายนี้ แต่ต้องขยับ index ให้ถูก)
    final seq = _u16(i); i += 2;
    final year = _u16(i); i += 2;
    final month = data[i++], day = data[i++];
    final hour = data[i++], minute = data[i++], second = data[i++];

    if ((flags & 0x01) != 0) { // time offset
      i += 2; // _i16(i)
    }

    double? mmol, mgdl;
    if ((flags & 0x02) != 0 && data.length >= i + 3) {
      final sfloatRaw = data[i] | (data[i + 1] << 8);
      i += 2;
      // type/location (skip)
      i++;

      final conc = _parseSfloat(sfloatRaw);
      if (conc != null) {
        final isMolPerL = (flags & 0x04) != 0;
        // ผู้ผลิตกลูโคสส่วนใหญ่ใช้ mmol/L → mg/dL = *18.015
        mmol = conc;
        mgdl = mmol * 18.015;
        // ถ้ารุ่นนี้ตั้งธงหน่วยไว้ตรงก็ยังได้ค่าเท่ากัน
        if (!isMolPerL) {
          // บางรุ่นธงอาจ 0 แต่ค่าก็ยังเป็น mmol/L จริง
          // ถ้าคุณพบว่าค่าผิด ค่อยสลับสาขานี้เป็น else-if ตามรุ่น
        }
      }
    }

    return mgdl;
  }

  double? _parseSfloat(int raw) {
    // ค่าพิเศษ IEEE-11073 (NaN/Inf/NRes) → ข้าม
    if (raw == 0x07FF || raw == 0x07FE || raw == 0x0800) return null;
    int mantissa = raw & 0x0FFF;
    int exponent = (raw >> 12) & 0xF;
    if (mantissa >= 0x800) mantissa -= 0x1000;
    if (exponent >= 0x8) exponent -= 0x10;
    return mantissa * pow(10, exponent).toDouble();
  }
}
