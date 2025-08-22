import 'package:hive/hive.dart';

class CareUnitStorage {
  static const String boxName = 'care_unit_box';

  // Save data พร้อม debug
  static Future<void> saveCareUnitData(Map<String, dynamic> data) async {
    try {
      print('💾 Saving to Hive: $data');
      var box = await Hive.openBox(boxName);
      await box.put('care_unit', data);
      print('✅ Saved successfully to Hive');
      
      // ตรวจสอบว่าบันทึกจริงหรือไม่
      final saved = box.get('care_unit');
      print('🔍 Verification - Saved data: $saved');
    } catch (e) {
      print('❌ Error saving to Hive: $e');
    }
  }

  // Load data พร้อม debug
  static Future<Map<String, dynamic>?> loadCareUnitData() async {
    try {
      var box = await Hive.openBox(boxName);
      final data = box.get('care_unit');
      print('📂 Loading from Hive: $data');
      
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data != null) {
        // ลองแปลงถ้าเป็น Map อื่น
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } catch (e) {
      print('❌ Error loading from Hive: $e');
      return null;
    }
  }

  // Delete data
  static Future<void> clearCareUnitData() async {
    try {
      var box = await Hive.openBox(boxName);
      await box.delete('care_unit');
      print('🗑️ Cleared care unit data from Hive');
    } catch (e) {
      print('❌ Error clearing Hive data: $e');
    }
  }
  
  // เพิ่มฟังก์ชันดูข้อมูลทั้งหมดใน Hive
  static Future<void> debugHiveContents() async {
    try {
      var box = await Hive.openBox(boxName);
      print('🔍 Hive Box Contents:');
      for (var key in box.keys) {
        print('  Key: $key, Value: ${box.get(key)}');
      }
    } catch (e) {
      print('❌ Error reading Hive contents: $e');
    }
  }
}
