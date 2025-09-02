import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_fr400.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_ha120.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_thermo_std.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_bp_std.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_jumper_oxi_cde81.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_glucose_std.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_yuwell_yx110.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_mi_bfs05hm.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_beurer_ft95.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_beurer_bm57.dart';
import 'package:smarttelemed_v4/core/device/session/detect/detect_bfs710_orchestrator.dart';


Future<ParserBinding> pickParser(
BluetoothDevice device,
List<BluetoothService> services,
) async {
// Order matters (mirrors your original screen logic)
final detectors = <Future<ParserBinding?> Function()>[
() => detectFr400(device, services),
() => detectHa120(device, services),
() => detectThermoStd(device, services),
() => detectFr400(device, services), // fallback path
() => detectJumperOxiCde81(device, services),
// PLX could be mapped to JumperOxi too if you add it later
() => detectYuwellYx110(device, services),
() => detectBpStd(device, services),
() => detectMiBfs05hm(device, services),
() => detectGlucoseStd(device, services),
() => detectBeurerBm57(device, services),
() => detectBeurerFt95(device, services),
() => detectBfs710(device, services),
];


for (final d in detectors) {
final res = await d();
if (res != null) return res;
}
throw Exception('ยังไม่รองรับอุปกรณ์นี้ (ไม่พบ Service/Characteristic ที่รู้จัก)');
}