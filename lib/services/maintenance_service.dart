import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/maintenance_event.dart';

class MaintenanceService {
  static const _key = 'wreniq_maintenance_events';

  static Future<List<MaintenanceEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return MaintenanceEvent.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _persist(List<MaintenanceEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(MaintenanceEvent event) async {
    final events = await load();
    events
      ..add(event)
      ..sort((a, b) => b.date.compareTo(a.date));
    await _persist(events);
  }

  static Future<void> delete(String id) async {
    final events = await load();
    events.removeWhere((e) => e.id == id);
    await _persist(events);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
