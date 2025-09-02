import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/shared/screens/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Beurer/beurer_tem_ft95.dart';


Future<ParserBinding?> detectBeurerFt95(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final name = device.platformName.toLowerCase();
final hasStdThermo = hasSvc(services, GuidRegistry.svcThermo) &&
hasChr(services, GuidRegistry.svcThermo, GuidRegistry.chrTemp);
if (name.contains('ft95') && hasStdThermo) {
final b = BeurerFt95(device: device);
await b.connect();
return ParserBinding.temp(b.onTemperature, cleanup: b.dispose);
}
return null;
}