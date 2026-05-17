// Represents a saved vehicle in the user's Garage.
// All Phase-7 fields default in fromJson so Phase 1–6 saved data still loads.
class Vehicle {
  final String id;
  final String nickname;   // user-defined label e.g. "Daily Driver"
  final String year;
  final String make;
  final String model;
  final String trim;       // trim level / grade
  final String engine;     // engine spec e.g. "2.5L 4-Cylinder"
  final String vin;        // 17-char VIN, empty if not entered
  final DateTime createdAt;
  final bool isPrimary;    // auto-selected for scans

  Vehicle({
    String? id,
    this.nickname = '',
    required this.year,
    required this.make,
    required this.model,
    required this.trim,
    this.engine = '',
    this.vin = '',
    DateTime? createdAt,
    this.isPrimary = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  // ── Display helpers ────────────────────────────────────────────────────────
  String get displayName        => '$year $make $model';
  String get fullDisplayName    => '$year $make $model — $trim';
  String get nicknameOrDefault  => nickname.isNotEmpty ? nickname : displayName;

  // ── Immutable update ───────────────────────────────────────────────────────
  Vehicle copyWith({
    String?   id,
    String?   nickname,
    String?   year,
    String?   make,
    String?   model,
    String?   trim,
    String?   engine,
    String?   vin,
    DateTime? createdAt,
    bool?     isPrimary,
  }) =>
      Vehicle(
        id:        id        ?? this.id,
        nickname:  nickname  ?? this.nickname,
        year:      year      ?? this.year,
        make:      make      ?? this.make,
        model:     model     ?? this.model,
        trim:      trim      ?? this.trim,
        engine:    engine    ?? this.engine,
        vin:       vin       ?? this.vin,
        createdAt: createdAt ?? this.createdAt,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  // ── Serialisation ──────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id':        id,
        'nickname':  nickname,
        'year':      year,
        'make':      make,
        'model':     model,
        'trim':      trim,
        'engine':    engine,
        'vin':       vin,
        'createdAt': createdAt.toIso8601String(),
        'isPrimary': isPrimary,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id:        json['id']        as String?   ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nickname:  json['nickname']  as String?   ?? '',
        year:      json['year']      as String,
        make:      json['make']      as String,
        model:     json['model']     as String,
        trim:      json['trim']      as String,
        engine:    json['engine']    as String?   ?? '',
        vin:       json['vin']       as String?   ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isPrimary: json['isPrimary'] as bool? ?? false,
      );
}
