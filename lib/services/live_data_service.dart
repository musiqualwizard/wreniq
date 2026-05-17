import 'dart:async';
import 'dart:math';
import '../models/live_data.dart';
import 'bluetooth_obd_service.dart';

class LiveDataService {
  static const bool _useMock = true;

  static Stream<LiveData> stream() =>
      BluetoothObdService.isConnected && !_useMock
          ? _liveStream()
          : _mockStream();

  static Stream<LiveData> _mockStream() async* {
    final rand = Random();

    double rpm         = 820;
    double speedKmh    = 0;
    double coolantTempC = 45;
    double intakeTempC  = 28;
    double batteryVoltage = 12.6;
    double fuelLevelPct   = 65;
    double engineLoadPct  = 15;
    double throttlePct    = 8;

    while (true) {
      await Future.delayed(const Duration(seconds: 1));

      // RPM: idle with occasional blips
      if (rand.nextDouble() < 0.12) {
        rpm = 2000 + rand.nextDouble() * 1000;
      } else {
        rpm += (rand.nextDouble() - 0.5) * 120;
        rpm = rpm.clamp(700, 900);
      }

      // Speed loosely follows RPM
      final targetSpeed = rpm > 1500 ? (rpm - 1500) / 50 : 0;
      speedKmh += (targetSpeed - speedKmh) * 0.3 + (rand.nextDouble() - 0.5) * 2;
      speedKmh = speedKmh.clamp(0, 180);

      // Coolant: slow warm-up to ~90°C operating temp
      if (coolantTempC < 90) {
        coolantTempC += rand.nextDouble() * 0.8;
      } else {
        coolantTempC += (rand.nextDouble() - 0.5) * 0.6;
        coolantTempC = coolantTempC.clamp(85, 98);
      }

      // Intake temp: slow random walk 20–45°C
      intakeTempC += (rand.nextDouble() - 0.5) * 0.4;
      intakeTempC = intakeTempC.clamp(20, 45);

      // Battery: alternator range 12.2–14.6V
      batteryVoltage += (rand.nextDouble() - 0.5) * 0.08;
      batteryVoltage = batteryVoltage.clamp(12.2, 14.6);

      // Fuel: very slow drain
      fuelLevelPct -= rand.nextDouble() * 0.005;
      fuelLevelPct = fuelLevelPct.clamp(0, 100);

      // Engine load + throttle track RPM
      engineLoadPct = ((rpm / 7000) * 100 + (rand.nextDouble() - 0.5) * 4).clamp(5, 100);
      throttlePct   = ((rpm / 7000) * 80  + (rand.nextDouble() - 0.5) * 3).clamp(3, 100);

      yield LiveData(
        rpm:            rpm,
        speedKmh:       speedKmh,
        coolantTempC:   coolantTempC,
        intakeTempC:    intakeTempC,
        batteryVoltage: batteryVoltage,
        fuelLevelPct:   fuelLevelPct,
        engineLoadPct:  engineLoadPct,
        throttlePct:    throttlePct,
        timestamp:      DateTime.now(),
        isMock:         true,
      );
    }
  }

  // static Stream<LiveData> _liveStream() => throw UnimplementedError();
  static Stream<LiveData> _liveStream() => _mockStream();
}
