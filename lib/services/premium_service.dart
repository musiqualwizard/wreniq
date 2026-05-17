import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService extends ChangeNotifier {
  static const _keyIsPro      = 'wreniq_is_pro_demo';
  static const _keyScanCount  = 'wreniq_free_scan_count';
  static const int freeScanLimit = 3;

  bool _isPro      = false;
  int  _scanCount  = 0;

  bool get isPro          => _isPro;
  int  get scanCount      => _scanCount;
  bool get canScan        => _isPro || _scanCount < freeScanLimit;
  int  get scansRemaining => _isPro ? -1 : (freeScanLimit - _scanCount).clamp(0, freeScanLimit);

  PremiumService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro      = prefs.getBool(_keyIsPro)     ?? false;
    _scanCount  = prefs.getInt(_keyScanCount)  ?? 0;
    notifyListeners();
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  Future<void> activateDemoPro() async {
    _isPro = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPro, true);
  }

  Future<void> deactivateDemoPro() async {
    _isPro = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPro, false);
  }

  // Call before each AI scan attempt. No-op when already Pro.
  Future<void> incrementScanCount() async {
    if (_isPro) return;
    _scanCount++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScanCount, _scanCount);
  }

  Future<void> resetScanCount() async {
    _scanCount = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScanCount, 0);
  }
}
