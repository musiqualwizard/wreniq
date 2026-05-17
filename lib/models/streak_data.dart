import 'dart:convert';

class StreakData {
  final int      currentStreak;
  final int      longestStreak;
  final DateTime? lastActiveDate;
  final int      totalDaysActive;
  final int      totalScans;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.totalDaysActive,
    required this.totalScans,
  });

  static StreakData get empty => const StreakData(
    currentStreak:  0,
    longestStreak:  0,
    lastActiveDate: null,
    totalDaysActive: 0,
    totalScans:     0,
  );

  StreakData copyWith({
    int?      currentStreak,
    int?      longestStreak,
    DateTime? lastActiveDate,
    int?      totalDaysActive,
    int?      totalScans,
  }) =>
      StreakData(
        currentStreak:  currentStreak  ?? this.currentStreak,
        longestStreak:  longestStreak  ?? this.longestStreak,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        totalDaysActive: totalDaysActive ?? this.totalDaysActive,
        totalScans:     totalScans     ?? this.totalScans,
      );

  Map<String, dynamic> toJson() => {
    'currentStreak':  currentStreak,
    'longestStreak':  longestStreak,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
    'totalDaysActive': totalDaysActive,
    'totalScans':     totalScans,
  };

  factory StreakData.fromJson(Map<String, dynamic> j) => StreakData(
    currentStreak:  j['currentStreak']  as int? ?? 0,
    longestStreak:  j['longestStreak']  as int? ?? 0,
    lastActiveDate: j['lastActiveDate'] != null
        ? DateTime.parse(j['lastActiveDate'] as String)
        : null,
    totalDaysActive: j['totalDaysActive'] as int? ?? 0,
    totalScans:     j['totalScans']     as int? ?? 0,
  );

  static StreakData fromRaw(String raw) {
    try {
      return StreakData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return StreakData.empty;
    }
  }
}
