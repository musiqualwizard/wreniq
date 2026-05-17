import 'dart:convert';

class RepairEstimate {
  final String id;
  final String partName;
  final String vehicleInfo;
  final double partsLow;
  final double partsHigh;
  final double laborLow;
  final double laborHigh;
  final double totalLow;
  final double totalHigh;
  final double laborHours;
  final String difficulty;
  final double diySavings;
  final String notes;
  final DateTime createdAt;
  final bool isMock;

  const RepairEstimate({
    required this.id,
    required this.partName,
    required this.vehicleInfo,
    required this.partsLow,
    required this.partsHigh,
    required this.laborLow,
    required this.laborHigh,
    required this.totalLow,
    required this.totalHigh,
    required this.laborHours,
    required this.difficulty,
    required this.diySavings,
    required this.notes,
    required this.createdAt,
    required this.isMock,
  });

  String get partsRange  => '\$${partsLow.toStringAsFixed(0)} – \$${partsHigh.toStringAsFixed(0)}';
  String get laborRange  => '\$${laborLow.toStringAsFixed(0)} – \$${laborHigh.toStringAsFixed(0)}';
  String get totalRange  => '\$${totalLow.toStringAsFixed(0)} – \$${totalHigh.toStringAsFixed(0)}';
  String get savingsText => '\$${diySavings.toStringAsFixed(0)}';

  Map<String, dynamic> toJson() => {
    'id':          id,
    'partName':    partName,
    'vehicleInfo': vehicleInfo,
    'partsLow':    partsLow,
    'partsHigh':   partsHigh,
    'laborLow':    laborLow,
    'laborHigh':   laborHigh,
    'totalLow':    totalLow,
    'totalHigh':   totalHigh,
    'laborHours':  laborHours,
    'difficulty':  difficulty,
    'diySavings':  diySavings,
    'notes':       notes,
    'createdAt':   createdAt.toIso8601String(),
    'isMock':      isMock,
  };

  factory RepairEstimate.fromJson(Map<String, dynamic> json) => RepairEstimate(
    id:          json['id'] as String,
    partName:    json['partName'] as String,
    vehicleInfo: json['vehicleInfo'] as String? ?? '',
    partsLow:    (json['partsLow'] as num).toDouble(),
    partsHigh:   (json['partsHigh'] as num).toDouble(),
    laborLow:    (json['laborLow'] as num).toDouble(),
    laborHigh:   (json['laborHigh'] as num).toDouble(),
    totalLow:    (json['totalLow'] as num).toDouble(),
    totalHigh:   (json['totalHigh'] as num).toDouble(),
    laborHours:  (json['laborHours'] as num).toDouble(),
    difficulty:  json['difficulty'] as String,
    diySavings:  (json['diySavings'] as num).toDouble(),
    notes:       json['notes'] as String? ?? '',
    createdAt:   DateTime.parse(json['createdAt'] as String),
    isMock:      json['isMock'] as bool? ?? true,
  );

  static RepairEstimate? tryFromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return RepairEstimate.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
