class SoundDiagnosis {
  final String soundType;
  final List<String> conditions;
  final List<String> likelyCauses;
  final String urgency;
  final String safeToDrive;
  final String costEstimate;
  final List<String> recommendedActions;
  final bool diyPossible;
  final String diySearchQuery;
  final DateTime diagnosedAt;

  SoundDiagnosis({
    required this.soundType,
    required this.conditions,
    required this.likelyCauses,
    required this.urgency,
    required this.safeToDrive,
    required this.costEstimate,
    required this.recommendedActions,
    required this.diyPossible,
    required this.diySearchQuery,
    required this.diagnosedAt,
  });

  bool get isCritical => urgency.contains('CRITICAL');
  bool get isHigh => urgency == 'High';
}
