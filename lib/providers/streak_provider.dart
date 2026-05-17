import 'package:flutter/material.dart';
import '../models/streak_data.dart';
import '../services/streak_service.dart';

class StreakProvider extends ChangeNotifier {
  StreakData _data = StreakData.empty;
  bool _loading = true;

  StreakData get data => _data;
  bool get isLoading => _loading;

  StreakProvider() {
    _init();
  }

  Future<void> _init() async {
    _data = await StreakService.recordLaunch();
    _loading = false;
    notifyListeners();
  }

  Future<void> incrementScans() async {
    _data = await StreakService.incrementScans();
    notifyListeners();
  }

  Future<void> refresh() async {
    _data = await StreakService.load();
    notifyListeners();
  }
}
