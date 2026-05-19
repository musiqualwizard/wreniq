import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeginnerModeService extends ChangeNotifier {
  static const _key = 'wreniq_beginner_mode';

  bool _enabled = false;
  bool get enabled => _enabled;

  BeginnerModeService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _enabled = !_enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _enabled);
  }
}
