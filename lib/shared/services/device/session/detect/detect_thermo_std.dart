import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/core/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/core/device/add_device/Yuwell/yuwell_yhw_6.dart';


Future<ParserBinding?> detectThermoStd(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final hasStdThermo = hasSvc(services, GuidRegistry.svcThermo) &&
hasChr(services, GuidRegistry.svcThermo, GuidRegistry.chrTemp);
if (hasStdThermo) {
final s = await YuwellYhw6(device: device).parse();
return ParserBinding.temp(s);
}
return null;
}