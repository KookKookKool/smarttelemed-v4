import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/shared/services/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/shared/services/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/shared/services/device/add_device/Jumper/jumper_jpd_bfs710.dart';
import 'package:smarttelemed_v4/shared/services/device/add_device/A&D/ua_651ble.dart';
import 'package:smarttelemed_v4/shared/services/device/add_device/Yuwell/yuwell_bp_ye680a.dart';


Future<ParserBinding?> detectBfs710(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final name = device.platformName.toLowerCase();
final suggestBfs = hasSvc(services, GuidRegistry.svcFfb0) ||
hasSvc(services, GuidRegistry.svcFee0) ||
name.contains('bfs') || name.contains('swan');


if (!suggestBfs) return null;


final bfs = JumperJpdBfs710(device: device, enableLog: false);
await bfs.start();


// Route to YE680A if name matches
if (name.contains('ye680a') || name.contains('ye680')) {
final s = await YuwellBpYe680a(device: device).parse();
return ParserBinding.map(s, cleanup: bfs.stop);
}


// If standard BP present, use it
final hasStdBp = hasSvc(services, GuidRegistry.svcBp) &&
hasChr(services, GuidRegistry.svcBp, GuidRegistry.chrBpMeas);
if (hasStdBp) {
final s = await AdUa651Ble(device: device).parse();
return ParserBinding.bp(s, cleanup: bfs.stop);
}


// Otherwise just weight
final weightStream = bfs.onWeightKg.map((kg) => {'weight_kg': kg.toStringAsFixed(1)});
return ParserBinding.map(weightStream, cleanup: bfs.stop);
}