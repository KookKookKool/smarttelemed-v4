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

class SessionStorage {
  static const String boxName = 'session_box';
  static const String sessionKey = 'user_session';

  // Save user session data
  static Future<void> saveSession({
    required String userType, // 'general', 'volunteer', 'hospital'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final sessionData = {
        'userType': userType,
        'loginTime': DateTime.now().toIso8601String(),
        'isLoggedIn': true,
        ...?additionalData,
      };

      print('💾 Saving session: $sessionData');
      var box = await Hive.openBox(boxName);
      await box.put(sessionKey, sessionData);
      print('✅ Session saved successfully');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  // Load session data
  static Future<Map<String, dynamic>?> loadSession() async {
    try {
      var box = await Hive.openBox(boxName);
      final data = box.get(sessionKey);
      print('📂 Loading session: $data');

      if (data is Map<String, dynamic>) {
        return data;
      } else if (data != null) {
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } catch (e) {
      print('❌ Error loading session: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final session = await loadSession();
      return session?['isLoggedIn'] == true;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // Get user type
  static Future<String?> getUserType() async {
    try {
      final session = await loadSession();
      return session?['userType'];
    } catch (e) {
      print('❌ Error getting user type: $e');
      return null;
    }
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    try {
      var box = await Hive.openBox(boxName);
      await box.delete(sessionKey);
      print('🗑️ Session cleared - user logged out');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  // Clear all app data (complete logout)
  static Future<void> clearAllData() async {
    try {
      await clearSession();
      await CareUnitStorage.clearCareUnitData();
      await IdCardStorage.clearIdCardData();
      print('🗑️ All app data cleared');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }
}

class IdCardStorage {
  static const String boxName = 'id_card_box';

  static const String storageKey = 'id_card';

  static Future<void> saveIdCardData(Map<String, dynamic> data) async {
    try {
      print('💾 Saving ID card to Hive: $data');
      var box = await Hive.openBox(boxName);
      await box.put(storageKey, data);
      print('✅ ID card saved successfully to Hive');
    } catch (e) {
      print('❌ Error saving ID card to Hive: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> loadIdCardData() async {
    try {
      var box = await Hive.openBox(boxName);
      final data = box.get(storageKey);
      print('📂 Loading ID card from Hive: $data');
      if (data is Map<String, dynamic>) return data;
      if (data != null) return Map<String, dynamic>.from(data as Map);
      return null;
    } catch (e) {
      print('❌ Error loading ID card from Hive: $e');
      return null;
    }
  }

  static Future<void> clearIdCardData() async {
    try {
      var box = await Hive.openBox(boxName);
      await box.delete(storageKey);
      print('🗑️ Cleared ID card data from Hive');
    } catch (e) {
      print('❌ Error clearing ID card data from Hive: $e');
    }
  }
}

class PatientIdCardStorage {
  static const String boxName = 'patient_id_card_box';
  static const String storageKey = 'patient_id_card';

  static Future<void> savePatientIdCardData(Map<String, dynamic> data) async {
    try {
      print('💾 Saving Patient ID card to Hive: $data');
      var box = await Hive.openBox(boxName);
      await box.put(storageKey, data);
      print('✅ Patient ID card saved successfully to Hive');
    } catch (e) {
      print('❌ Error saving Patient ID card to Hive: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> loadPatientIdCardData() async {
    try {
      var box = await Hive.openBox(boxName);
      final data = box.get(storageKey);
      print('📂 Loading Patient ID card from Hive: $data');
      if (data is Map<String, dynamic>) return data;
      if (data != null) return Map<String, dynamic>.from(data as Map);
      return null;
    } catch (e) {
      print('❌ Error loading Patient ID card from Hive: $e');
      return null;
    }
  }

  static Future<void> clearPatientIdCardData() async {
    try {
      var box = await Hive.openBox(boxName);
      await box.delete(storageKey);
      print('🗑️ Cleared Patient ID card data from Hive');
    } catch (e) {
      print('❌ Error clearing Patient ID card data from Hive: $e');
    }
  }
}

class VitalsStorage {
  static const String boxName = 'vitals_box';
  static const String storageKey = 'vitals_data';

  static Future<void> saveVitalsData(Map<String, dynamic> data) async {
    try {
      print('💾 Saving Vitals to Hive: $data');
      var box = await Hive.openBox(boxName);

      // เพิ่ม timestamp และ ID สำหรับการส่งแต่ละครั้ง
      final vitalsData = {
        ...data,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'submitTime': DateTime.now().toLocal().toString(),
      };

      // เก็บเป็น List เพื่อเก็บประวัติการส่งทั้งหมด
      List<dynamic> existingData = box.get(storageKey, defaultValue: []);
      existingData.add(vitalsData);

      await box.put(storageKey, existingData);
      print('✅ Vitals saved successfully to Hive');
    } catch (e) {
      print('❌ Error saving Vitals to Hive: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadVitalsData() async {
    try {
      var box = await Hive.openBox(boxName);
      final data = box.get(storageKey);
      print('📂 Loading Vitals from Hive: $data');

      if (data is List) {
        return data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading Vitals from Hive: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> loadLatestVitalsData() async {
    try {
      final allData = await loadVitalsData();
      if (allData.isNotEmpty) {
        return allData.last; // ข้อมูลล่าสุด
      }
      return null;
    } catch (e) {
      print('❌ Error loading latest Vitals from Hive: $e');
      return null;
    }
  }

  static Future<void> clearVitalsData() async {
    try {
      var box = await Hive.openBox(boxName);
      await box.delete(storageKey);
      print('🗑️ Cleared Vitals data from Hive');
    } catch (e) {
      print('❌ Error clearing Vitals data from Hive: $e');
    }
  }
}
