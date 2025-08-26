import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/core/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';


Future<ParserBinding?> detectBpStd(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final hasStdBp = hasSvc(services, GuidRegistry.svcBp) &&
hasChr(services, GuidRegistry.svcBp, GuidRegistry.chrBpMeas);
if (hasStdBp) {
final s = await AdUa651Ble(device: device).parse();
return ParserBinding.bp(s);
}
return null;
}