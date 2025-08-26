import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:smarttelemed_v4/core/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/core/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/core/device/add_device/Beurer/beurer_bm57.dart';
import 'package:smarttelemed_v4/core/device/add_device/A&D/ua_651ble.dart';


Future<ParserBinding?> detectBeurerBm57(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final name = device.platformName.toLowerCase();
final hasStdBp = hasSvc(services, GuidRegistry.svcBp) &&
hasChr(services, GuidRegistry.svcBp, GuidRegistry.chrBpMeas);


if (name.contains('bm57') && hasStdBp) {
final b = BeurerBm57(device: device);
await b.start();
return ParserBinding.map(b.onBloodPressure, cleanup: b.stop);
}


// fallback: if std BP, just use standard profile
if (hasStdBp) {
final s = await AdUa651Ble(device: device).parse();
return ParserBinding.bp(s);
}


return null;
}