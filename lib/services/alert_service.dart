// Phase 2: replace _pending list with flutter_local_notifications package
class LocalAlert {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;

  const LocalAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });
}

class AlertService {
  static final List<LocalAlert> _pending = [];

  static void schedule({
    required String title,
    required String body,
    required DateTime when,
  }) {
    _pending.add(LocalAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      scheduledAt: when,
    ));
  }

  static List<LocalAlert> getPending() => List.unmodifiable(_pending);

  static void clear() => _pending.clear();

  static void scheduleMaintenanceReminder(String item, DateTime dueDate) {
    schedule(
      title: 'Maintenance Due: $item',
      body: 'Your $item service is due on ${_fmt(dueDate)}. Schedule an appointment.',
      when: dueDate.subtract(const Duration(days: 7)),
    );
  }

  static void scheduleStreakReminder() {
    schedule(
      title: "Don't break your streak!",
      body: 'Open Wreniq today to keep your streak alive.',
      when: DateTime.now().add(const Duration(hours: 22)),
    );
  }

  static String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
