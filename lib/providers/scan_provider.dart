import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../services/ai_scan_service.dart';
import '../services/storage_service.dart';

enum ScanState { idle, scanning, done, error }

class ScanProvider extends ChangeNotifier {
  List<ScanResult> _savedScans    = [];
  ScanResult?      _currentResult;
  ScanState        _state          = ScanState.idle;
  String           _errorMessage   = '';
  bool             _lastWasMock    = false;
  String?          _fallbackReason;

  List<ScanResult> get savedScans     => _savedScans;
  ScanResult?      get currentResult  => _currentResult;
  ScanState        get state          => _state;
  String           get errorMessage   => _errorMessage;
  /// True when the most recent scan used mock data (no key, or live call failed).
  bool             get lastWasMock    => _lastWasMock;
  /// Non-null when a live call failed and we fell back to mock — contains the
  /// user-friendly reason to show in the results screen banner.
  String?          get fallbackReason => _fallbackReason;

  ScanProvider() {
    _loadScans();
  }

  Future<void> _loadScans() async {
    _savedScans = await StorageService.loadScans();
    notifyListeners();
  }

  Future<void> analyzePart({
    required String imagePath,
    required String year,
    required String make,
    required String model,
    required String trim,
  }) async {
    _state        = ScanState.scanning;
    _errorMessage = '';
    _fallbackReason = null;
    notifyListeners();

    try {
      final analysis = await AiScanService.analyze(
        imagePath: imagePath,
        year:      year,
        make:      make,
        model:     model,
        trim:      trim,
      );
      _currentResult  = analysis.result;
      _lastWasMock    = analysis.wasMock;
      _fallbackReason = analysis.fallbackReason;
      _state          = ScanState.done;
    } on Exception catch (e) {
      // Map well-known exceptions to friendly messages; keep a safe fallback
      // for anything unexpected.
      _state        = ScanState.error;
      _errorMessage = _friendlyMessage(e);
    }

    notifyListeners();
  }

  Future<void> saveCurrentScan() async {
    if (_currentResult == null) return;
    await StorageService.saveScan(_currentResult!);
    await _loadScans();
  }

  Future<void> deleteScan(String id) async {
    await StorageService.deleteScan(id);
    await _loadScans();
  }

  void resetScan() {
    _state          = ScanState.idle;
    _currentResult  = null;
    _fallbackReason = null;
    notifyListeners();
  }

  // Used by SavedScansScreen to re-open a historical scan.
  // Historical scans don't carry a mock/live flag, so we clear it.
  void viewSavedScan(ScanResult scan) {
    _currentResult  = scan;
    _lastWasMock    = false;
    _fallbackReason = null;
    _state          = ScanState.done;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _friendlyMessage(Exception e) {
    final msg = e.toString();
    if (msg.contains('too large'))     return 'Image is too large. Please choose a photo under 4 MB.';
    if (msg.contains('not configured')) return 'Backend not configured. Check backendUrl in lib/config/api_config.dart.';
    if (msg.contains('No internet') || msg.contains('SocketException')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('timed out'))     return 'Request timed out. Check your connection and try again.';
    if (msg.contains('HTTP 4') || msg.contains('HTTP 5')) {
      return 'AI service error. Please try again in a moment.';
    }
    return 'Analysis failed. Please try again.';
  }
}
