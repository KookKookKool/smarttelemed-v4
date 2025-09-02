import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:smarttelemed_v4/shared/screens/device/session/guid_registry.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/parser_binding.dart';
import 'detect_utils.dart';
import 'package:smarttelemed_v4/shared/screens/device/add_device/Mi/mibfs_05hm.dart';


Future<ParserBinding?> detectMiBfs05hm(
BluetoothDevice device,
List<BluetoothService> services,
) async {
final hasMibfs = hasSvc(services, GuidRegistry.svcBody) ||
hasChr(services, GuidRegistry.svcBody, GuidRegistry.chrBodyMx) ||
hasAnyChr(services, GuidRegistry.chr1530) ||
hasAnyChr(services, GuidRegistry.chr1531) ||
hasAnyChr(services, GuidRegistry.chr1532) ||
hasAnyChr(services, GuidRegistry.chr1542) ||
hasAnyChr(services, GuidRegistry.chr1543) ||
hasAnyChr(services, GuidRegistry.chr2A2Fv);


if (hasMibfs) {
final s = await MiBfs05hm(device: device).parse();
return ParserBinding.map(s);
}
return null;
}