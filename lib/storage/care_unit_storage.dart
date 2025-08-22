import 'package:hive/hive.dart';

class CareUnitStorage {
  static const String boxName = 'care_unit_box';

  // Save data
  static Future<void> saveCareUnitData(Map<String, dynamic> data) async {
    var box = await Hive.openBox(boxName);
    await box.put('care_unit', data);
  }

  // Load data
  static Future<Map<String, dynamic>?> loadCareUnitData() async {
    var box = await Hive.openBox(boxName);
    final data = box.get('care_unit');
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  // Delete data
  static Future<void> clearCareUnitData() async {
    var box = await Hive.openBox(boxName);
    await box.delete('care_unit');
  }
}
