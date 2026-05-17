import '../models/vehicle_health.dart';
import '../models/scan_result.dart';

class VehicleHealthService {
  static VehicleHealth calculate({
    List<ScanResult> recentScans = const [],
    int diagnosticCodeCount = 0,
    bool hasCriticalCodes = false,
    bool maintenanceOverdue = false,
    double batteryVoltage = 12.6,
    double coolantTempC = 85.0,
    int unresolvedIssues = 0,
  }) {
    int score = 100;
    final issues    = <String>[];
    final positives = <String>[];

    // Critical / active fault codes
    if (hasCriticalCodes) {
      score -= 30;
      issues.add('Critical diagnostic codes detected');
    } else if (diagnosticCodeCount > 0) {
      score -= (diagnosticCodeCount * 8).clamp(0, 40);
      issues.add('$diagnosticCodeCount diagnostic code${diagnosticCodeCount > 1 ? 's' : ''} active');
    }

    // Scheduled maintenance
    if (maintenanceOverdue) {
      score -= 15;
      issues.add('Scheduled maintenance overdue');
    }

    // Battery voltage
    if (batteryVoltage < 11.8) {
      score -= 20;
      issues.add('Battery critically low (${batteryVoltage.toStringAsFixed(1)} V)');
    } else if (batteryVoltage < 12.2) {
      score -= 10;
      issues.add('Battery voltage low (${batteryVoltage.toStringAsFixed(1)} V)');
    } else {
      positives.add('Battery voltage normal');
    }

    // Coolant temperature
    if (coolantTempC >= 105) {
      score -= 25;
      issues.add('Engine overheating (${coolantTempC.toStringAsFixed(0)} °C)');
    } else if (coolantTempC >= 95) {
      score -= 10;
      issues.add('Coolant temp elevated (${coolantTempC.toStringAsFixed(0)} °C)');
    } else {
      positives.add('Coolant temperature normal');
    }

    // Unresolved scan issues
    if (unresolvedIssues > 2) {
      score -= 10;
      issues.add('Multiple unresolved repair issues');
    } else if (unresolvedIssues > 0) {
      score -= 5;
      issues.add('$unresolvedIssues unresolved issue${unresolvedIssues > 1 ? 's' : ''}');
    }

    if (recentScans.isNotEmpty) positives.add('Active vehicle monitoring');
    if (issues.isEmpty)         positives.add('No known issues detected');

    final clamped = score.clamp(0, 100);
    return VehicleHealth(
      score:        clamped,
      status:       VehicleHealth.statusFromScore(clamped),
      issues:       issues,
      positives:    positives,
      calculatedAt: DateTime.now(),
    );
  }

  // Demo score shown before any real data is available.
  static VehicleHealth demo() => VehicleHealth(
    score:        88,
    status:       HealthStatus.excellent,
    issues:       [],
    positives:    ['No known issues detected', 'Active vehicle monitoring', 'Battery voltage normal'],
    calculatedAt: DateTime.now(),
  );
}
