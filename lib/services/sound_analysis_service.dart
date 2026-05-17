import '../models/sound_diagnosis.dart';

// Heuristic sound diagnosis database.
// Phase 2: replace with backend ML audio analysis endpoint.
class SoundAnalysisService {
  static const _db = <String, _Entry>{
    'Squealing': _Entry(
      likelyCauses: [
        'Worn brake pads contacting the rotor wear indicator (most common)',
        'Slipping or worn serpentine/accessory belt',
        'Dry or seized brake caliper slide pins',
      ],
      urgency: 'High',
      safeToDrive: 'Short distances only — get inspected today',
      costEstimate: '\$100–\$350 (brake pads + labour) or \$75–\$200 (belt)',
      recommendedActions: [
        'Inspect brake pad thickness from wheel gap',
        'Check serpentine belt for cracks or glazing',
        'Listen whether sound occurs only when braking (pads) or always (belt)',
      ],
      diyPossible: true,
      diySearch: 'squealing brakes how to inspect worn brake pads',
    ),
    'Grinding': _Entry(
      likelyCauses: [
        'Severely worn brake pads — metal grinding on rotor',
        'Wheel bearing failure (constant grinding that varies with speed)',
        'Debris or stone caught in the brake assembly',
      ],
      urgency: 'CRITICAL',
      safeToDrive: 'NO — brake failure risk is imminent. Stop driving.',
      costEstimate: '\$200–\$500 (brakes and rotors) or \$200–\$500 (wheel bearing)',
      recommendedActions: [
        'Stop driving immediately if braking is affected',
        'Have the vehicle towed to a mechanic if brakes feel soft or unresponsive',
        'Check if grinding is constant (bearing) or only when braking (pads/rotors)',
      ],
      diyPossible: false,
      diySearch: 'grinding noise car brakes wheel bearing diagnosis repair',
    ),
    'Knocking': _Entry(
      likelyCauses: [
        'Engine knock (detonation) — low octane fuel or carbon buildup',
        'Worn connecting rod bearing — serious internal engine damage',
        'Low oil pressure — check oil level immediately',
      ],
      urgency: 'CRITICAL',
      safeToDrive: 'NO — check oil level immediately. Stop driving if low.',
      costEstimate: '\$500–\$4,000+ depending on severity and repair needed',
      recommendedActions: [
        'Check engine oil level right away — top up if low',
        'Check oil pressure warning light',
        'If knock persists after oil top-up, tow to mechanic — do not continue driving',
      ],
      diyPossible: false,
      diySearch: 'engine knocking noise diagnosis causes fix rod bearing',
    ),
    'Ticking': _Entry(
      likelyCauses: [
        'Low engine oil level (most common — check first)',
        'Worn valve train components: lifters, rocker arms, or cam followers',
        'Exhaust manifold leak (ticking that gets louder when cold)',
      ],
      urgency: 'High',
      safeToDrive: 'Check oil level first. If OK, limit driving until inspected.',
      costEstimate: '\$50 (oil top-up) to \$1,500+ (valve train repair)',
      recommendedActions: [
        'Pull over safely and check engine oil level on the dipstick',
        'Listen whether ticking is louder when cold (exhaust) or constant (valve train)',
        'Book an inspection if oil level is fine — do not ignore valve train noise',
      ],
      diyPossible: true,
      diySearch: 'engine ticking noise low oil level valve train fix',
    ),
    'Clicking': _Entry(
      likelyCauses: [
        'Worn CV joint — clicking primarily when turning (front-wheel drive)',
        'Loose wheel cover, hubcap, or lug nut',
        'Failing starter solenoid (rapid clicking when starting)',
        'Low oil level at startup (single tick)',
      ],
      urgency: 'Medium',
      safeToDrive: 'OK for short local distances — avoid sharp full-lock turns',
      costEstimate: '\$200–\$500 (CV axle replacement) or \$5–\$30 (hubcap)',
      recommendedActions: [
        'Test by turning sharply at low speed to confirm CV joint',
        'Physically check that all lug nuts are tight',
        'If clicking only on startup: check battery voltage and starter connections',
      ],
      diyPossible: true,
      diySearch: 'clicking noise when turning CV joint diagnosis fix',
    ),
    'Hissing': _Entry(
      likelyCauses: [
        'Vacuum hose leak — often under the hood near the intake manifold',
        'Coolant leak from a hose, radiator, or water pump',
        'AC refrigerant leak (hissing from engine bay or dashboard)',
        'Power steering fluid leak',
      ],
      urgency: 'Medium-High',
      safeToDrive: 'Monitor temperature gauge closely — stop immediately if overheating',
      costEstimate: '\$30–\$400 depending on source and component',
      recommendedActions: [
        'Open the hood with engine off — smell for coolant (sweet) or burning',
        'Check coolant reservoir level and inspect visible hoses',
        'If hissing from dashboard: do not use AC until inspected (refrigerant leak)',
      ],
      diyPossible: true,
      diySearch: 'hissing sound under hood vacuum leak coolant leak diagnosis',
    ),
    'Rattling': _Entry(
      likelyCauses: [
        'Loose or broken heat shield on exhaust pipe (very common)',
        'Loose exhaust pipe, catalytic converter, or muffler',
        'Worn sway bar end links or bushings',
        'Low transmission or differential fluid',
      ],
      urgency: 'Low-Medium',
      safeToDrive: 'Yes — but get inspected within a week',
      costEstimate: '\$30–\$300 depending on which component is loose',
      recommendedActions: [
        'Inspect under the car for loose heat shields — a common rattle at low cost to fix',
        'Shake exhaust components while cold to find loose sections',
        'Check transmission fluid level if rattle occurs under acceleration',
      ],
      diyPossible: true,
      diySearch: 'rattling noise under car heat shield exhaust loose fix',
    ),
    'Clunking': _Entry(
      likelyCauses: [
        'Worn ball joint or tie rod end (clunk over bumps and turns)',
        'Broken or worn sway bar link',
        'Loose or worn shock absorber/strut mount',
        'Worn engine or transmission mount',
      ],
      urgency: 'High',
      safeToDrive: 'Limit to slow local driving only — suspension failure risk',
      costEstimate: '\$100–\$600 depending on which component needs replacement',
      recommendedActions: [
        'Listen whether clunk is front or rear — helps narrow down the component',
        'Inspect sway bar links by wiggling the bar while parked',
        'Book a suspension inspection — worn ball joints are a safety critical failure',
      ],
      diyPossible: false,
      diySearch: 'clunking noise suspension ball joint sway bar link repair',
    ),
  };

  static SoundDiagnosis? diagnose({
    required String soundType,
    List<String> conditions = const [],
  }) {
    final entry = _db[soundType];
    if (entry == null) return null;
    return SoundDiagnosis(
      soundType:          soundType,
      conditions:         conditions,
      likelyCauses:       entry.likelyCauses,
      urgency:            entry.urgency,
      safeToDrive:        entry.safeToDrive,
      costEstimate:       entry.costEstimate,
      recommendedActions: entry.recommendedActions,
      diyPossible:        entry.diyPossible,
      diySearchQuery:     entry.diySearch,
      diagnosedAt:        DateTime.now(),
    );
  }

  static List<String> get soundTypes => _db.keys.toList();
}

class _Entry {
  final List<String> likelyCauses;
  final String urgency;
  final String safeToDrive;
  final String costEstimate;
  final List<String> recommendedActions;
  final bool diyPossible;
  final String diySearch;

  const _Entry({
    required this.likelyCauses,
    required this.urgency,
    required this.safeToDrive,
    required this.costEstimate,
    required this.recommendedActions,
    required this.diyPossible,
    required this.diySearch,
  });
}
