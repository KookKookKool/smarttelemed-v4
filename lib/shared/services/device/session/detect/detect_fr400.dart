import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/shared/services/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/shared/services/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/shared/services/device/add_device/Jumper/jumper_jpd_fr400.dart';


Future<ParserBinding?> detectFr400(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final name = device.platformName.toLowerCase();
final isFr400Name = name.contains('fr400') ||
name.contains('jpd-fr400') ||
name.contains('jpd fr400') ||
name.contains('jpdfr400');


final hasFff0 = hasSvc(services, GuidRegistry.svcFff0);
final hasStdThermo = hasSvc(services, GuidRegistry.svcThermo) &&
hasChr(services, GuidRegistry.svcThermo, GuidRegistry.chrTemp);
final hasStdBp = hasSvc(services, GuidRegistry.svcBp) &&
hasChr(services, GuidRegistry.svcBp, GuidRegistry.chrBpMeas);


if (isFr400Name && hasFff0 && !hasStdThermo && !hasStdBp) {
final stream = JumperFr400(device: device).parse; // Stream<Map<String,String>>
return ParserBinding.map(stream, isThermo: true);
}


// Fallback heuristic
final maybeThermoByName = name.contains('therm') ||
isFr400Name ||
(name.contains('jumper') && !name.contains('ha120'));


if (hasFff0 && !hasStdThermo && !hasStdBp && maybeThermoByName) {
final stream = JumperFr400(device: device).parse;
return ParserBinding.map(stream, isThermo: true);
}


return null;
}