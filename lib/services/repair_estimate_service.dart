import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnostic_code.dart';
import '../models/repair_estimate.dart';
import '../models/scan_result.dart';

class RepairEstimateService {
  static const _prefsKey = 'repair_estimates_v1';

  // ── Public estimators ─────────────────────────────────────────────────────────

  static RepairEstimate estimateFromScan(ScanResult scan) {
    final (pLow, pHigh) = _partsCostFromScan(scan);
    final (lLow, lHigh, lHrs) = _laborFromDifficulty(scan.repairDifficulty);
    final savings = (lLow + lHigh) / 2;
    return RepairEstimate(
      id:          _newId(),
      partName:    scan.partName,
      vehicleInfo: scan.vehicleInfo,
      partsLow:    pLow,
      partsHigh:   pHigh,
      laborLow:    lLow,
      laborHigh:   lHigh,
      totalLow:    pLow + lLow,
      totalHigh:   pHigh + lHigh,
      laborHours:  lHrs,
      difficulty:  scan.repairDifficulty,
      diySavings:  savings,
      notes:       '',
      createdAt:   DateTime.now(),
      isMock:      true,
    );
  }

  static RepairEstimate estimateFromDiagCode(
    DiagnosticCode code, {
    String vehicleInfo = '',
  }) {
    final (tLow, tHigh) = _parsePriceString(code.estimatedRepairCost);
    final pLow  = tLow  * 0.55;
    final pHigh = tHigh * 0.60;
    final lLow  = tLow  * 0.40;
    final lHigh = tHigh * 0.45;
    final diff  = _difficultyFromSeverity(code.severity);
    final (_, _, lHrs) = _laborFromDifficulty(diff);
    final savings = (lLow + lHigh) / 2;
    return RepairEstimate(
      id:          _newId(),
      partName:    '${code.code} – ${code.title}',
      vehicleInfo: vehicleInfo,
      partsLow:    pLow,
      partsHigh:   pHigh,
      laborLow:    lLow,
      laborHigh:   lHigh,
      totalLow:    pLow + lLow,
      totalHigh:   pHigh + lHigh,
      laborHours:  lHrs,
      difficulty:  diff,
      diySavings:  savings,
      notes:       '',
      createdAt:   DateTime.now(),
      isMock:      true,
    );
  }

  // ── SharedPreferences persistence ─────────────────────────────────────────────

  static Future<void> saveEstimate(RepairEstimate estimate) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadEstimates();
    existing.removeWhere((e) => e.id == estimate.id);
    existing.insert(0, estimate);
    final jsonList = existing.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  static Future<List<RepairEstimate>> loadEstimates() async {
    final prefs   = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_prefsKey) ?? [];
    return strings
        .map(RepairEstimate.tryFromJsonString)
        .whereType<RepairEstimate>()
        .toList();
  }

  static Future<void> deleteEstimate(String id) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadEstimates();
    existing.removeWhere((e) => e.id == id);
    final jsonList = existing.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  static String _newId() =>
      'est_${DateTime.now().millisecondsSinceEpoch}';

  static (double low, double high) _partsCostFromScan(ScanResult scan) {
    if (scan.estimatedPriceLow > 0 && scan.estimatedPriceHigh > 0) {
      return (scan.estimatedPriceLow, scan.estimatedPriceHigh);
    }
    return _parsePriceString(scan.priceEstimate);
  }

  static (double low, double high) _parsePriceString(String price) {
    final cleaned = price.replaceAll(r'$', '').replaceAll(',', '');
    final parts   = cleaned.split(RegExp(r'[–\-—]'));
    if (parts.length >= 2) {
      final low  = double.tryParse(parts[0].trim()) ?? 0;
      final high = double.tryParse(parts[1].trim()) ?? 0;
      if (low > 0 || high > 0) return (low, high);
    }
    final single = double.tryParse(cleaned.trim()) ?? 100;
    return (single * 0.75, single * 1.25);
  }

  // Returns (laborLow, laborHigh, midpointHours).
  static (double, double, double) _laborFromDifficulty(String difficulty) =>
      switch (difficulty.toLowerCase()) {
        'beginner'     => (43.0, 130.0, 1.0),   // 0.5–1.5h @ $85–$130
        'advanced'     => (255.0, 780.0, 4.5),   // 3.0–6.0h @ $85–$130
        _              => (128.0, 390.0, 2.5),   // Intermediate: 1.5–3.0h
      };

  static String _difficultyFromSeverity(DiagnosticSeverity s) => switch (s) {
    DiagnosticSeverity.critical => 'Advanced',
    DiagnosticSeverity.high     => 'Advanced',
    DiagnosticSeverity.medium   => 'Intermediate',
    DiagnosticSeverity.low      => 'Beginner',
  };
}
