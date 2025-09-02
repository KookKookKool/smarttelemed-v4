import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/shared/screens/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:intl/intl.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Yuwell/yuwell_glucose.dart';


String _fmtThai(String iso) {
try {
final dt = DateTime.parse(iso).toLocal();
return DateFormat('d MMM yyyy HH:mm', 'th_TH').format(dt);
} catch (_) { return iso; }
}


Future<ParserBinding?> detectGlucoseStd(
BluetoothDevice device,
List<BluetoothService> services,
) async {
if (hasSvc(services, GuidRegistry.svcGlucose) &&
hasChr(services, GuidRegistry.svcGlucose, GuidRegistry.chrGluMeas) &&
hasChr(services, GuidRegistry.svcGlucose, GuidRegistry.chrGluRacp)) {
final y = YuwellGlucose(device: device);
final stream = y.records(fetchLastOnly: true).take(1).map<Map<String, String>>((m) {
String labelType(int v) {
switch (v) {
case 0x1: return 'Whole blood (capillary)';
case 0x2: return 'Plasma (capillary)';
case 0x3: return 'Whole blood (venous)';
case 0x4: return 'Plasma (venous)';
case 0xA: return 'Control solution';
default: return 'Type 0x${v.toRadixString(16)}';
}
}
String labelLoc(int v) {
switch (v) {
case 0x1: return 'Finger';
case 0x2: return 'AST';
case 0x3: return 'Earlobe';
case 0x4: return 'Control';
case 0xF: return 'Unspecified';
default: return 'Loc 0x${v.toRadixString(16)}';
}
}
final t = int.tryParse(m['type'] ?? '') ?? -1;
final lc = int.tryParse(m['loc'] ?? '') ?? -1;
return {
'mgdl': m['mgdl'] ?? '-',
'mmol': m['mmol'] ?? '-',
'seq' : m['seq'] ?? '-',
'ts' : _fmtThai(m['time'] ?? m['timestamp'] ?? ''),
'type': labelType(t),
'loc' : labelLoc(lc),
};
});
return ParserBinding.map(stream);
}
return null;
}