// Snapshot of live OBD2 vehicle data. All values are READ-ONLY.
// This model never issues any commands to the vehicle ECU.
class LiveData {
  final double rpm;            // engine revolutions per minute
  final double speedKmh;       // vehicle speed km/h
  final double coolantTempC;   // engine coolant temperature °C
  final double intakeTempC;    // intake air temperature °C
  final double batteryVoltage; // system voltage (V)
  final double fuelLevelPct;   // fuel tank level 0–100 %
  final double engineLoadPct;  // calculated engine load 0–100 %
  final double throttlePct;    // throttle position 0–100 %
  final DateTime timestamp;
  final bool isMock;

  const LiveData({
    required this.rpm,
    required this.speedKmh,
    required this.coolantTempC,
    required this.intakeTempC,
    required this.batteryVoltage,
    required this.fuelLevelPct,
    required this.engineLoadPct,
    required this.throttlePct,
    required this.timestamp,
    required this.isMock,
  });

  // ── Warning thresholds (informational only) ───────────────────────────────────

  bool get isOverheating  => coolantTempC >= 105;
  bool get isTempHigh     => coolantTempC >= 95 && !isOverheating;
  bool get isLowVoltage   => batteryVoltage < 11.8;
  bool get isVoltageLow   => batteryVoltage < 12.4 && !isLowVoltage;
  bool get isHighRpm      => rpm >= 6000;
  bool get isCriticalFuel => fuelLevelPct <= 10;
  bool get isFuelLow      => fuelLevelPct <= 20 && !isCriticalFuel;
  bool get isLoadHigh     => engineLoadPct > 80;

  bool get hasAnyWarning =>
      isOverheating || isTempHigh ||
      isLowVoltage  || isVoltageLow ||
      isHighRpm     || isCriticalFuel || isFuelLow;
}
