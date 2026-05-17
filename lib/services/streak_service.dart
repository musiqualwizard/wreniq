import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_data.dart';

class StreakService {
  static const _key = 'wreniq_streak_v1';

  static Future<StreakData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    if (raw == null) return StreakData.empty;
    return StreakData.fromRaw(raw);
  }

  // Call once per app launch to update the streak counter.
  // Returns the updated StreakData.
  static Future<StreakData> recordLaunch() async {
    final current = await load();
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);

    if (current.lastActiveDate == null) {
      // First ever launch
      final updated = current.copyWith(
        currentStreak:   1,
        longestStreak:   1,
        lastActiveDate:  today,
        totalDaysActive: 1,
      );
      await _persist(updated);
      return updated;
    }

    final last = DateTime(
      current.lastActiveDate!.year,
      current.lastActiveDate!.month,
      current.lastActiveDate!.day,
    );

    if (last == today) {
      // Same day — no change to streak
      return current;
    }

    final diff = today.difference(last).inDays;

    int newStreak;
    if (diff == 1) {
      // Consecutive day
      newStreak = current.currentStreak + 1;
    } else {
      // Streak broken
      newStreak = 1;
    }

    final updated = current.copyWith(
      currentStreak:   newStreak,
      longestStreak:   newStreak > current.longestStreak ? newStreak : current.longestStreak,
      lastActiveDate:  today,
      totalDaysActive: current.totalDaysActive + 1,
    );
    await _persist(updated);
    return updated;
  }

  static Future<StreakData> incrementScans() async {
    final current = await load();
    final updated = current.copyWith(totalScans: current.totalScans + 1);
    await _persist(updated);
    return updated;
  }

  static Future<void> _persist(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}
