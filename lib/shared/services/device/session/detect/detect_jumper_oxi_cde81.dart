import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/core/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/core/device/add_device/Jumper/jumper_po_jpd_500f.dart';


Future<ParserBinding?> detectJumperOxiCde81(
BluetoothDevice device,
List<BluetoothService> services,
) async {
if (hasAnyChr(services, GuidRegistry.chrCde81)) {
final s = await JumperPoJpd500f(device: device).parse();
return ParserBinding.map(s);
}
return null;
}