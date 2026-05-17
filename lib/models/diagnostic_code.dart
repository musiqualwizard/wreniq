import 'dart:convert';

enum DiagnosticSeverity { critical, high, medium, low }

class DiagnosticCode {
  final String code;
  final String title;
  final DiagnosticSeverity severity;
  final String explanation;
  final List<String> possibleCauses;
  final List<String> recommendedActions;
  final List<String> suggestedSearchTerms;
  final bool safeToDrive;
  final String estimatedRepairCost;
  final DateTime detectedAt;

  DiagnosticCode({
    required this.code,
    required this.title,
    required this.severity,
    required this.explanation,
    required this.possibleCauses,
    required this.recommendedActions,
    required this.suggestedSearchTerms,
    required this.safeToDrive,
    required this.estimatedRepairCost,
    required this.detectedAt,
  });

  String get severityLabel => switch (severity) {
    DiagnosticSeverity.critical => 'CRITICAL',
    DiagnosticSeverity.high     => 'HIGH',
    DiagnosticSeverity.medium   => 'MEDIUM',
    DiagnosticSeverity.low      => 'LOW',
  };

  // Short part-search name used as ScanResult.partName when opening FindPartsScreen.
  String get partSearchName {
    final words = title.split(' ').take(5).join(' ');
    return '$code – $words';
  }

  Map<String, dynamic> toJson() => {
    'code':                code,
    'title':               title,
    'severity':            severity.name,
    'explanation':         explanation,
    'possibleCauses':      possibleCauses,
    'recommendedActions':  recommendedActions,
    'suggestedSearchTerms': suggestedSearchTerms,
    'safeToDrive':         safeToDrive,
    'estimatedRepairCost': estimatedRepairCost,
    'detectedAt':          detectedAt.toIso8601String(),
  };

  factory DiagnosticCode.fromJson(Map<String, dynamic> json) => DiagnosticCode(
    code:                json['code']  as String,
    title:               json['title'] as String,
    severity: DiagnosticSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
      orElse: () => DiagnosticSeverity.low,
    ),
    explanation:         json['explanation'] as String,
    possibleCauses:      List<String>.from(json['possibleCauses'] as List),
    recommendedActions:  List<String>.from(json['recommendedActions'] as List),
    suggestedSearchTerms: json['suggestedSearchTerms'] != null
        ? List<String>.from(json['suggestedSearchTerms'] as List)
        : [],
    safeToDrive:         json['safeToDrive'] as bool? ?? true,
    estimatedRepairCost: json['estimatedRepairCost'] as String,
    detectedAt:          DateTime.parse(json['detectedAt'] as String),
  );
}

// ── Scan Session ──────────────────────────────────────────────────────────────

class ObdScanSession {
  final String id;
  final DateTime scannedAt;
  final List<DiagnosticCode> codes;
  final bool isMock;

  const ObdScanSession({
    required this.id,
    required this.scannedAt,
    required this.codes,
    required this.isMock,
  });

  int get codeCount => codes.length;

  Map<String, dynamic> toJson() => {
    'id':        id,
    'scannedAt': scannedAt.toIso8601String(),
    'codes':     codes.map((c) => c.toJson()).toList(),
    'isMock':    isMock,
  };

  factory ObdScanSession.fromJson(Map<String, dynamic> json) => ObdScanSession(
    id:        json['id'] as String,
    scannedAt: DateTime.parse(json['scannedAt'] as String),
    codes: (json['codes'] as List)
        .map((c) => DiagnosticCode.fromJson(c as Map<String, dynamic>))
        .toList(),
    isMock: json['isMock'] as bool? ?? true,
  );

  static ObdScanSession? tryFromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return ObdScanSession.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
