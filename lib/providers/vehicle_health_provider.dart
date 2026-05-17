import 'package:flutter/foundation.dart';
import '../models/vehicle_health.dart';
import '../models/scan_result.dart';
import '../services/vehicle_health_service.dart';

class VehicleHealthProvider extends ChangeNotifier {
  VehicleHealth _health = VehicleHealthService.demo();

  VehicleHealth  get health => _health;
  int            get score  => _health.score;
  HealthStatus   get status => _health.status;

  void recalculate({
    List<ScanResult> recentScans       = const [],
    int    diagnosticCodeCount         = 0,
    bool   hasCriticalCodes            = false,
    bool   maintenanceOverdue          = false,
    double batteryVoltage              = 12.6,
    double coolantTempC                = 85.0,
    int    unresolvedIssues            = 0,
  }) {
    _health = VehicleHealthService.calculate(
      recentScans:          recentScans,
      diagnosticCodeCount:  diagnosticCodeCount,
      hasCriticalCodes:     hasCriticalCodes,
      maintenanceOverdue:   maintenanceOverdue,
      batteryVoltage:       batteryVoltage,
      coolantTempC:         coolantTempC,
      unresolvedIssues:     unresolvedIssues,
    );
    notifyListeners();
  }

  void resetToDemo() {
    _health = VehicleHealthService.demo();
    notifyListeners();
  }
}
