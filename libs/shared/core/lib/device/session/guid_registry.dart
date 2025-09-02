import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';


class GuidRegistry {
// Vendor / common
static final svcFff0 = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
static final haChrFff1 = Guid('0000fff1-0000-1000-8000-00805f9b34fb');
static final haChrFff2 = Guid('0000fff2-0000-1000-8000-00805f9b34fb');


// BP (standard)
static final svcBp = Guid('00001810-0000-1000-8000-00805f9b34fb');
static final chrBpMeas = Guid('00002a35-0000-1000-8000-00805f9b34fb');


// Thermometer (standard)
static final svcThermo = Guid('00001809-0000-1000-8000-00805f9b34fb');
static final chrTemp = Guid('00002a1c-0000-1000-8000-00805f9b34fb');


// Glucose (standard)
static final svcGlucose = Guid('00001808-0000-1000-8000-00805f9b34fb');
static final chrGluMeas = Guid('00002a18-0000-1000-8000-00805f9b34fb');
static final chrGluRacp = Guid('00002a52-0000-1000-8000-00805f9b34fb');


// PLX (optional)
static final svcPlx = Guid('00001822-0000-1000-8000-00805f9b34fb');
static final chrPlxCont = Guid('00002a5f-0000-1000-8000-00805f9b34fb');
static final chrPlxSpot = Guid('00002a5e-0000-1000-8000-00805f9b34fb');


// Yuwell-like oximeter
static final svcFfe0 = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
static final chrFfe4 = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');


// Body composition & Xiaomi proprietary
static final svcBody = Guid('0000181b-0000-1000-8000-00805f9b34fb');
static final chrBodyMx = Guid('00002a9c-0000-1000-8000-00805f9b34fb');
static final chr1530 = Guid('00001530-0000-3512-2118-0009af100700');
static final chr1531 = Guid('00001531-0000-3512-2118-0009af100700');
static final chr1532 = Guid('00001532-0000-3512-2118-0009af100700');
static final chr1542 = Guid('00001542-0000-3512-2118-0009af100700');
static final chr1543 = Guid('00001543-0000-3512-2118-0009af100700');
static final chr2A2Fv = Guid('00002a2f-0000-3512-2118-0009af100700');


// Jumper oximeter (special char lock)
static final chrCde81 = Guid('cdeacb81-5235-4c07-8846-93a37ee6b86d');


// BFS-710 services
static final svcFfb0 = Guid('0000ffb0-0000-1000-8000-00805f9b34fb');
static final svcFee0 = Guid('0000fee0-0000-1000-8000-00805f9b34fb');
}