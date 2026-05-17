enum RecallSeverity { safety, emissions, defect }

class RecallAlert {
  final String id;
  final String title;
  final String description;
  final String component;
  final RecallSeverity severity;
  final String remedy;
  final String nhtsaNumber;
  final DateTime reportedDate;
  final bool isMock;

  const RecallAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.component,
    required this.severity,
    required this.remedy,
    required this.nhtsaNumber,
    required this.reportedDate,
    required this.isMock,
  });

  String get severityLabel => switch (severity) {
    RecallSeverity.safety    => 'Safety',
    RecallSeverity.emissions => 'Emissions',
    RecallSeverity.defect    => 'Defect',
  };
}
