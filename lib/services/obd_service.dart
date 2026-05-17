import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnostic_code.dart';

// OBD2 service — mock mode only in Phase 11.
// When flutter_blue_plus (or a similar plugin) is added, set _useMock = false
// and implement _liveScan() using the BT plugin's RFCOMM socket API.
class ObdService {
  static const bool _useMock = true;
  static const String _prefKey = 'obd_last_session';

  // ── Public API ───────────────────────────────────────────────────────────────

  static Future<ObdScanSession> scan() async {
    if (_useMock) return _mockScan();
    // TODO(bt): return await _liveScan();
    return _mockScan();
  }

  static Future<ObdScanSession?> loadLastSession() async {
    final prefs = await SharedPreferences.getInstance();
    return ObdScanSession.tryFromJsonString(prefs.getString(_prefKey));
  }

  static Future<void> saveSession(ObdScanSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(session.toJson()));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  // ── Mock implementation ───────────────────────────────────────────────────────

  static Future<ObdScanSession> _mockScan() async {
    // Simulate adapter negotiation + scan delay.
    await Future.delayed(const Duration(milliseconds: 1800));

    final rng   = Random();
    final count = 1 + rng.nextInt(3); // 1–3 codes
    final pool  = List.of(_mockCodeLibrary)..shuffle(rng);
    final now   = DateTime.now();

    final codes = pool.take(count).map((builder) => builder(now)).toList();

    return ObdScanSession(
      id:        now.millisecondsSinceEpoch.toString(),
      scannedAt: now,
      codes:     codes,
      isMock:    true,
    );
  }

  // Each entry is a factory so detectedAt can be set at scan time.
  static final List<DiagnosticCode Function(DateTime)> _mockCodeLibrary = [
    (t) => DiagnosticCode(
      code:     'P0301',
      title:    'Cylinder 1 Misfire Detected',
      severity: DiagnosticSeverity.high,
      explanation:
          'The ECM detected irregular firing in cylinder 1. Sustained misfires '
          'can overheat and damage the catalytic converter.',
      possibleCauses: [
        'Fouled or worn spark plug',
        'Faulty ignition coil',
        'Leaking fuel injector',
        'Low compression in cylinder 1',
        'Vacuum leak near cylinder 1',
      ],
      recommendedActions: [
        'Replace spark plug in cylinder 1',
        'Swap ignition coil to another cylinder to test',
        'Check fuel injector spray pattern',
        'Perform a cylinder compression test',
      ],
      suggestedSearchTerms: ['spark plug', 'ignition coil', 'fuel injector'],
      safeToDrive:         false,
      estimatedRepairCost: '\$150 – \$400',
      detectedAt:          t,
    ),

    (t) => DiagnosticCode(
      code:     'P0420',
      title:    'Catalyst System Efficiency Below Threshold (Bank 1)',
      severity: DiagnosticSeverity.medium,
      explanation:
          'The downstream O2 sensor sees less conversion than expected. '
          'The catalytic converter may be contaminated or failing.',
      possibleCauses: [
        'Failing catalytic converter',
        'Faulty downstream oxygen sensor',
        'Engine misfires contaminating the cat',
        'Exhaust leak upstream of the cat',
        'Wrong fuel type used',
      ],
      recommendedActions: [
        'Test downstream O2 sensor live data',
        'Inspect for exhaust leaks before the cat',
        'Resolve any misfire codes first (P03xx)',
        'Replace catalytic converter if sensors test normal',
      ],
      suggestedSearchTerms: [
        'catalytic converter',
        'downstream oxygen sensor',
        'O2 sensor',
      ],
      safeToDrive:         true,
      estimatedRepairCost: '\$400 – \$1,200',
      detectedAt:          t,
    ),

    (t) => DiagnosticCode(
      code:     'P0171',
      title:    'System Too Lean, Bank 1',
      severity: DiagnosticSeverity.medium,
      explanation:
          'The fuel system is running with too much air relative to fuel on '
          'Bank 1. The ECM has reached its maximum fuel-trim correction.',
      possibleCauses: [
        'Dirty or failing MAF sensor',
        'Vacuum leak in intake system',
        'Weak fuel pump or clogged fuel filter',
        'Faulty upstream oxygen sensor',
        'Torn intake boot',
      ],
      recommendedActions: [
        'Clean MAF sensor with MAF cleaner spray',
        'Inspect all vacuum lines for cracks or disconnections',
        'Check fuel pressure at the rail',
        'Inspect intake boot for tears',
      ],
      suggestedSearchTerms: [
        'MAF sensor',
        'mass airflow sensor',
        'vacuum hose kit',
        'fuel pressure regulator',
      ],
      safeToDrive:         true,
      estimatedRepairCost: '\$80 – \$350',
      detectedAt:          t,
    ),

    (t) => DiagnosticCode(
      code:     'P0128',
      title:    'Coolant Temp Below Thermostat Regulating Temp',
      severity: DiagnosticSeverity.low,
      explanation:
          'The engine is not reaching normal operating temperature within the '
          'expected time, most likely caused by a thermostat stuck open.',
      possibleCauses: [
        'Thermostat stuck in the open position',
        'Faulty coolant temperature sensor',
        'Low coolant level',
      ],
      recommendedActions: [
        'Replace thermostat (inexpensive, high-impact fix)',
        'Verify coolant temperature sensor reads correctly',
        'Check coolant level and condition',
      ],
      suggestedSearchTerms: [
        'thermostat',
        'coolant temperature sensor',
        'coolant',
      ],
      safeToDrive:         true,
      estimatedRepairCost: '\$25 – \$120',
      detectedAt:          t,
    ),

    (t) => DiagnosticCode(
      code:     'P0456',
      title:    'Evaporative Emission System Small Leak Detected',
      severity: DiagnosticSeverity.low,
      explanation:
          'A very small leak has been detected in the EVAP system that captures '
          'fuel vapors. Often caused by a loose gas cap.',
      possibleCauses: [
        'Loose or faulty gas cap',
        'Cracked EVAP hose',
        'Faulty purge control valve',
        'Faulty EVAP vent valve',
        'Damaged fuel tank seam',
      ],
      recommendedActions: [
        'Tighten gas cap firmly, clear code, and re-test',
        'Inspect EVAP hoses for visible cracks',
        'Test purge valve with a smoke machine',
        'Replace gas cap if damaged',
      ],
      suggestedSearchTerms: [
        'gas cap',
        'EVAP purge valve',
        'EVAP canister vent valve',
      ],
      safeToDrive:         true,
      estimatedRepairCost: '\$20 – \$200',
      detectedAt:          t,
    ),
  ];

  // ── Future Bluetooth hooks (stubbed — do not implement until flutter_blue_plus added) ──

  // static Future<List<Object>> scanForAdapters() => throw UnimplementedError(
  //     'BT adapter scan not implemented. Add flutter_blue_plus first.');

  // static Future<void> connect(String deviceId) => throw UnimplementedError(
  //     'BT connect not implemented. Add flutter_blue_plus first.');
}
