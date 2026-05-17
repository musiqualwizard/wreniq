import 'package:flutter/foundation.dart';
import '../models/maintenance_event.dart';
import '../services/maintenance_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  List<MaintenanceEvent> _events = [];
  bool _isLoading = true;

  List<MaintenanceEvent> get events    => List.unmodifiable(_events);
  bool                   get isLoading => _isLoading;

  List<MaintenanceEvent> get overdueEvents  =>
      _events.where((e) => e.isOverdue).toList();
  List<MaintenanceEvent> get upcomingEvents =>
      _events.where((e) => e.isDueSoon && !e.isOverdue).toList();

  double get totalTrackedCost =>
      _events.fold(0.0, (sum, e) => sum + (e.cost ?? 0.0));

  MaintenanceProvider() {
    _load();
  }

  Future<void> _load() async {
    _events = await MaintenanceService.load();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEvent(MaintenanceEvent event) async {
    await MaintenanceService.add(event);
    await _load();
  }

  Future<void> deleteEvent(String id) async {
    await MaintenanceService.delete(id);
    await _load();
  }

  Future<void> refresh() => _load();
}
