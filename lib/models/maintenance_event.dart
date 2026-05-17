import 'dart:convert';

enum MaintenanceType { oilChange, brakes, tires, battery, repair, inspection, other }

class MaintenanceEvent {
  final String id;
  final MaintenanceType type;
  final String title;
  final String notes;
  final DateTime date;
  final int? mileage;
  final DateTime? nextDueDate;
  final int? nextDueMileage;
  final double? cost;

  const MaintenanceEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.notes,
    required this.date,
    this.mileage,
    this.nextDueDate,
    this.nextDueMileage,
    this.cost,
  });

  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final diff = nextDueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  String get typeLabel => switch (type) {
    MaintenanceType.oilChange   => 'Oil Change',
    MaintenanceType.brakes      => 'Brakes',
    MaintenanceType.tires       => 'Tires',
    MaintenanceType.battery     => 'Battery',
    MaintenanceType.repair      => 'Repair',
    MaintenanceType.inspection  => 'Inspection',
    MaintenanceType.other       => 'Other',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'notes': notes,
    'date': date.toIso8601String(),
    'mileage': mileage,
    'nextDueDate': nextDueDate?.toIso8601String(),
    'nextDueMileage': nextDueMileage,
    'cost': cost,
  };

  factory MaintenanceEvent.fromJson(Map<String, dynamic> j) => MaintenanceEvent(
    id:    j['id']    as String,
    type:  MaintenanceType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => MaintenanceType.other,
    ),
    title: j['title'] as String,
    notes: j['notes'] as String? ?? '',
    date:  DateTime.parse(j['date'] as String),
    mileage:        j['mileage']        as int?,
    nextDueDate:    j['nextDueDate']    != null
        ? DateTime.parse(j['nextDueDate'] as String)
        : null,
    nextDueMileage: j['nextDueMileage'] as int?,
    cost:           (j['cost'] as num?)?.toDouble(),
  );

  static List<MaintenanceEvent> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MaintenanceEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
