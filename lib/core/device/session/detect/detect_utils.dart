import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;


bool hasSvc(List<BluetoothService> services, Guid svc) =>
services.any((s) => s.uuid == svc);


bool hasChr(List<BluetoothService> services, Guid svc, Guid chr) {
final s = services.where((x) => x.uuid == svc);
if (s.isEmpty) return false;
return s.first.characteristics.any((c) => c.uuid == chr);
}


bool hasAnyChr(List<BluetoothService> services, Guid chr) {
for (final s in services) {
for (final c in s.characteristics) {
if (c.uuid == chr) return true;
}
}
return false;
}