// lib/core/device/device_prefs.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DevicePrefs {
  static const String installedKey = 'installed_device_ids';
  static const String aliasKey = 'device_aliases';

  /// อ่านรายการอุปกรณ์ที่บันทึกถาวร
  static Future<Set<String>> getInstalledIds() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(installedKey) ?? const <String>[];
    return list.where((e) => e.trim().isNotEmpty).toSet();
    }

  /// บันทึกรายการอุปกรณ์ที่บันทึกถาวร (เขียนทับทั้งหมด)
  static Future<void> saveInstalledIds(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(installedKey, ids.toList());
  }

  /// เพิ่มอุปกรณ์ ถ้ายังไม่มี
  static Future<bool> addInstalledId(String id) async {
    final s = await getInstalledIds();
    final added = s.add(id);
    if (added) await saveInstalledIds(s);
    return added;
  }

  /// ลบอุปกรณ์ ถ้ามี
  static Future<bool> removeInstalledId(String id) async {
    final s = await getInstalledIds();
    final removed = s.remove(id);
    if (removed) await saveInstalledIds(s);
    return removed;
  }

  /// อ่าน mapping ของชื่อเล่น { id: alias }
  static Future<Map<String, String>> getAliases() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(aliasKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = json.decode(raw);
      if (m is Map) {
        return m.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (_) {}
    return {};
  }

  /// เซ็ตชื่อเล่นของ id (ส่ง null/ว่าง = ลบชื่อเล่น)
  static Future<void> setAlias(String id, String? alias) async {
    final p = await SharedPreferences.getInstance();
    final m = await getAliases();
    if (alias == null || alias.trim().isEmpty) {
      m.remove(id);
    } else {
      m[id] = alias.trim();
    }
    await p.setString(aliasKey, json.encode(m));
  }

  /// คืนค่า name ที่ใช้แสดง (alias ถ้ามี ไม่งั้นใช้ id)
  static String displayName(String id, Map<String, String> aliases) {
    final a = aliases[id]?.trim();
    return (a != null && a.isNotEmpty) ? a : id;
  }
}
