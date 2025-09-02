// lib/core/device/session/detect/detect_bp_std.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/shared/screens/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/A&D/ua_651ble.dart';

Future<ParserBinding?> detectBpStd(
  BluetoothDevice device,
  List<BluetoothService> services,
) async {
  final ok = hasSvc(services, GuidRegistry.svcBp) &&
      hasChr(services, GuidRegistry.svcBp, GuidRegistry.chrBpMeas);
  if (!ok) return null;

  final raw = await AdUa651Ble(device: device).parse();

  // 1) ถ้า parser ให้ Stream<BpReading> มาก็ใช้ทางลัดเลย
  if (raw is Stream<BpReading>) {
    if (kDebugMode) print('[UA-651] using BpReading stream');
    return ParserBinding.bp(raw);
  }

  // 2) กรณีอื่น map → sys/dia/pul (string) แบบปลอดภัยด้วยการ cast เป็น Map ก่อน
  if (raw is Stream) {
    num? toNum(dynamic v) => v == null ? null : (v is num ? v : num.tryParse(v.toString()));

    T? pick<T>(Map<Object?, Object?> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null) return v as T?;
      }
      return null;
    }

    Stream<Map> mapped = raw.map<Map>((event) {
      final out = <String, String>{};

      // กรณี event เป็น Map (เช่น {sys:.., dia:.., pul:..} หรือชื่อคีย์อื่น)
      if (event is Map) {
        final m = event as Map<Object?, Object?>;
        final sys = toNum(pick(m, ['sys', 'systolic', 'Sys', 'SYS']));
        final dia = toNum(pick(m, ['dia', 'diastolic', 'Dia', 'DIA']));
        final pul = toNum(pick(m, ['pul', 'pr', 'PR', 'pulse', 'HeartRate']));
        if (sys != null) out['sys'] = sys.round().toString();
        if (dia != null) out['dia'] = dia.round().toString();
        if (pul != null) out['pul'] = pul.round().toString();
        return out;
      }

      // กรณีเป็นอ็อบเจ็กต์อื่น ให้ลอง dynamic fields
      try {
        final x = event as dynamic;
        final sys = toNum(x.sys ?? x.systolic);
        final dia = toNum(x.dia ?? x.diastolic);
        final pul = toNum(x.pul ?? x.pr ?? x.pulse ?? x.heartRate);
        if (sys != null) out['sys'] = sys.round().toString();
        if (dia != null) out['dia'] = dia.round().toString();
        if (pul != null) out['pul'] = pul.round().toString();
      } catch (_) {
        // ignore
      }
      return out;
    });

    if (kDebugMode) {
      mapped = mapped.map((m) {
        print('[UA-651] normalized map => $m');
        return m;
      });
    }

    return ParserBinding.map(mapped);
  }

  if (kDebugMode) {
    print('[UA-651] unknown parse() return type: ${raw.runtimeType}');
  }
  return null;
}
