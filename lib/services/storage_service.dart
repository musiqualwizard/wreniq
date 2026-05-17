import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/scan_result.dart';

// All local persistence for the app — backed by shared_preferences.
class StorageService {
  static const String _vehicleKey = 'saved_vehicle';
  static const String _scansKey   = 'saved_scans';

  static Future<void> saveVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
  }

  static Future<Vehicle?> loadVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_vehicleKey);
    if (data == null) return null;
    return Vehicle.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  // Inserts the new scan at the front so the list is newest-first.
  static Future<void> saveScan(ScanResult scan) async {
    final scans = await loadScans();
    scans.insert(0, scan);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scansKey,
      jsonEncode(scans.map((s) => s.toJson()).toList()),
    );
  }

  static Future<List<ScanResult>> loadScans() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_scansKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((item) => ScanResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteScan(String id) async {
    final scans = await loadScans();
    scans.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _scansKey,
      jsonEncode(scans.map((s) => s.toJson()).toList()),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
