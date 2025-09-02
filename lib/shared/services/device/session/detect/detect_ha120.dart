import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/core/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_jpd_ha120.dart';


Future<ParserBinding?> detectHa120(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final name = device.platformName.toLowerCase();
final hasFff0 = hasSvc(services, GuidRegistry.svcFff0);
final hasHaVendor = hasFff0 &&
(hasChr(services, GuidRegistry.svcFff0, GuidRegistry.haChrFff1) ||
hasChr(services, GuidRegistry.svcFff0, GuidRegistry.haChrFff2));
final isHa120Name = name.contains('ha120') || name.contains('jpd-ha120');


if (isHa120Name || hasHaVendor) {
final s = await JumperJpdHa120(device: device).parse();
return ParserBinding.map(s);
}
return null;
}