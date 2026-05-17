enum HealthStatus { excellent, good, warning, critical }

class VehicleHealth {
  final int score; // 0–100
  final HealthStatus status;
  final List<String> issues;
  final List<String> positives;
  final DateTime calculatedAt;

  const VehicleHealth({
    required this.score,
    required this.status,
    required this.issues,
    required this.positives,
    required this.calculatedAt,
  });

  static HealthStatus statusFromScore(int score) {
    if (score >= 85) return HealthStatus.excellent;
    if (score >= 65) return HealthStatus.good;
    if (score >= 40) return HealthStatus.warning;
    return HealthStatus.critical;
  }

  String get statusLabel => switch (status) {
    HealthStatus.excellent => 'Excellent',
    HealthStatus.good      => 'Good',
    HealthStatus.warning   => 'Warning',
    HealthStatus.critical  => 'Critical',
  };
}
