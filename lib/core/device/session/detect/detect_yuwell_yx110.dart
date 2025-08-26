import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/core/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_fpo_yx110.dart';


Future<ParserBinding?> detectYuwellYx110(
BluetoothDevice device,
List<BluetoothService> services,
) async {
if (hasSvc(services, GuidRegistry.svcFfe0) &&
hasChr(services, GuidRegistry.svcFfe0, GuidRegistry.chrFfe4)) {
final s = await YuwellFpoYx110(device: device).parse();
return ParserBinding.map(s);
}
return null;
}