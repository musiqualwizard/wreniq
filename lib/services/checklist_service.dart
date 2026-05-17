import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Persists which tool and step indices the user has checked off for a given
// scan. Keys are scoped to the scan ID so progress doesn't bleed between scans.
class ChecklistService {
  static String _toolsKey(String scanId) => 'repair_tools_$scanId';
  static String _stepsKey(String scanId) => 'repair_steps_$scanId';

  static Future<Set<int>> loadCheckedTools(String scanId) =>
      _load(_toolsKey(scanId));

  static Future<Set<int>> loadCheckedSteps(String scanId) =>
      _load(_stepsKey(scanId));

  static Future<void> saveCheckedTools(String scanId, Set<int> checked) =>
      _save(_toolsKey(scanId), checked);

  static Future<void> saveCheckedSteps(String scanId, Set<int> checked) =>
      _save(_stepsKey(scanId), checked);

  static Future<void> clearAll(String scanId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_toolsKey(scanId));
    await prefs.remove(_stepsKey(scanId));
  }

  static Future<Set<int>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).map((e) => e as int).toSet();
  }

  static Future<void> _save(String key, Set<int> checked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(checked.toList()..sort()));
  }
}
