import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

// Persists a list of Vehicle objects.
// On first load it migrates the old single-vehicle key ('saved_vehicle')
// written by StorageService so existing users keep their data.
class GarageService {
  static const _key       = 'garage_vehicles';
  static const _legacyKey = 'saved_vehicle'; // StorageService wrote here pre-Phase-7

  static Future<List<Vehicle>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        return (jsonDecode(raw) as List)
            .map((j) => Vehicle.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // corrupt data — fall through to legacy check
      }
    }

    // One-time migration: import the single vehicle saved before Phase 7
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null) {
      try {
        final map = jsonDecode(legacy) as Map<String, dynamic>;
        final v   = Vehicle.fromJson({...map, 'isPrimary': true});
        await saveAll([v]);
        return [v];
      } catch (_) {}
    }

    return [];
  }

  static Future<void> saveAll(List<Vehicle> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(vehicles.map((v) => v.toJson()).toList()),
    );
  }
}
