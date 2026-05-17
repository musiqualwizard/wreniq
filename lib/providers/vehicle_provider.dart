import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/garage_service.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  List<Vehicle> get vehicles   => List.unmodifiable(_vehicles);
  bool get isLoading           => _isLoading;
  bool get hasVehicle          => _vehicles.isNotEmpty;

  // Primary vehicle — backward-compat alias used everywhere pre-Phase-7
  Vehicle? get vehicle         => primaryVehicle;
  Vehicle? get primaryVehicle {
    try {
      return _vehicles.firstWhere((v) => v.isPrimary);
    } catch (_) {
      return _vehicles.isNotEmpty ? _vehicles.first : null;
    }
  }

  VehicleProvider() {
    _load();
  }

  Future<void> _load() async {
    _vehicles  = await GarageService.loadAll();
    _isLoading = false;
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addVehicle(Vehicle v) async {
    // First vehicle added becomes primary automatically
    final asNew = _vehicles.isEmpty ? v.copyWith(isPrimary: true) : v;
    _vehicles.add(asNew);
    await _persist();
  }

  Future<void> updateVehicle(Vehicle v) async {
    final i = _vehicles.indexWhere((x) => x.id == v.id);
    if (i == -1) return;
    _vehicles[i] = v;
    await _persist();
  }

  Future<void> deleteVehicle(String id) async {
    final wasPrimary = _vehicles.any((v) => v.id == id && v.isPrimary);
    _vehicles.removeWhere((v) => v.id == id);
    if (wasPrimary && _vehicles.isNotEmpty) {
      _vehicles[0] = _vehicles[0].copyWith(isPrimary: true);
    }
    await _persist();
  }

  Future<void> setPrimary(String id) async {
    _vehicles = _vehicles
        .map((v) => v.copyWith(isPrimary: v.id == id))
        .toList();
    await _persist();
  }

  // Backward-compat: VehicleSetupScreen calls setVehicle(Vehicle(...)).
  // Adds vehicle as new primary (or updates if id already exists).
  Future<void> setVehicle(Vehicle vehicle) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicle.id);
    _vehicles = _vehicles.map((v) => v.copyWith(isPrimary: false)).toList();
    if (idx != -1) {
      _vehicles[idx] = vehicle.copyWith(isPrimary: true);
    } else {
      _vehicles.add(vehicle.copyWith(isPrimary: true));
    }
    await _persist();
  }

  Future<void> clearVehicle() async {
    _vehicles.clear();
    await _persist();
  }

  Future<void> _persist() async {
    await GarageService.saveAll(_vehicles);
    notifyListeners();
  }
}
