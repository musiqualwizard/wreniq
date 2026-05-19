import 'package:flutter/material.dart';
import '../models/fluid_leak.dart';

class LeakService {
  static List<FluidLeak> get all => _leaks;

  // Returns ranked matches based on color category and location
  static List<FluidLeak> identify({
    required String colorCategory, // 'black_brown' | 'red_pink' | 'green_yellow' | 'clear' | 'dark_brown'
    required String location,       // 'front' | 'center' | 'rear' | 'unknown'
  }) {
    return _leaks.where((leak) {
      final matchesColor = _colorMatches(leak.id, colorCategory);
      final matchesLocation = location == 'unknown' ||
          leak.leakLocations.contains(location) ||
          leak.leakLocations.contains('anywhere');
      return matchesColor && matchesLocation;
    }).toList()
      ..sort((a, b) => _severityRank(b.severity) - _severityRank(a.severity));
  }

  static bool _colorMatches(String id, String cat) {
    const map = <String, List<String>>{
      'black_brown': ['engine_oil', 'old_atf', 'gear_oil'],
      'red_pink':    ['atf', 'power_steering'],
      'green_yellow':['coolant'],
      'clear':       ['brake_fluid', 'washer_fluid', 'gasoline', 'water'],
      'dark_brown':  ['engine_oil', 'old_atf', 'gear_oil'],
      'orange':      ['coolant', 'atf'],
    };
    return map[cat]?.contains(id) ?? false;
  }

  static int _severityRank(String s) {
    switch (s) {
      case 'Critical': return 4;
      case 'High':     return 3;
      case 'Medium':   return 2;
      default:         return 1;
    }
  }

  static const _leaks = <FluidLeak>[
    FluidLeak(
      id: 'engine_oil',
      fluidType: 'Engine Oil',
      typicalColor: Color(0xFF3D2400),
      colorDescription: 'Dark brown to black',
      severity: 'High',
      driveableNow: false,
      texture: 'Slick and oily',
      smell: 'Burnt oil smell',
      commonCauses: [
        'Worn valve cover gasket',
        'Degraded oil pan gasket',
        'Cracked oil pan',
        'Loose drain plug',
        'Worn rear main seal',
      ],
      whatToDo:
          'Check your oil level with the dipstick immediately. If critically low, do NOT drive — top up first. Have the source of the leak repaired promptly.',
      beginnerExplanation:
          'Oil keeps your engine\'s moving parts from grinding together. A dark puddle under the engine is almost always oil. Low oil = engine destruction.',
      leakLocations: ['front', 'center', 'anywhere'],
    ),
    FluidLeak(
      id: 'coolant',
      fluidType: 'Coolant / Antifreeze',
      typicalColor: Color(0xFF00C853),
      colorDescription: 'Bright green, orange, pink, or blue (depends on brand)',
      severity: 'Critical',
      driveableNow: false,
      texture: 'Watery and slippery',
      smell: 'Sweet, maple-syrup-like smell',
      commonCauses: [
        'Leaking radiator hose',
        'Cracked radiator',
        'Failing water pump',
        'Blown head gasket',
        'Loose hose clamp',
      ],
      whatToDo:
          'Do NOT drive with a coolant leak — the engine will overheat rapidly. Check coolant reservoir level. Get the car towed if very low.',
      beginnerExplanation:
          'Coolant is the coloured liquid that stops your engine from overheating. It smells sweet. Losing it means your engine could overheat and break — a very expensive fix.',
      leakLocations: ['front', 'center', 'anywhere'],
    ),
    FluidLeak(
      id: 'brake_fluid',
      fluidType: 'Brake Fluid',
      typicalColor: Color(0xFFF5F0D0),
      colorDescription: 'Clear to light yellow (darkens with age)',
      severity: 'Critical',
      driveableNow: false,
      texture: 'Slightly oily, slippery',
      smell: 'Almost odorless or faintly chemical',
      commonCauses: [
        'Cracked brake line',
        'Leaking brake caliper',
        'Damaged master cylinder',
        'Worn wheel cylinder (drum brakes)',
      ],
      whatToDo:
          'DO NOT DRIVE. Brake fluid loss means your brakes may FAIL. Tow the vehicle immediately. This is a safety emergency.',
      beginnerExplanation:
          'Brake fluid is what makes your brakes work when you press the pedal. If it leaks out your brakes stop working. This is extremely dangerous.',
      leakLocations: ['front', 'center', 'rear', 'anywhere'],
    ),
    FluidLeak(
      id: 'atf',
      fluidType: 'Transmission Fluid (ATF)',
      typicalColor: Color(0xFFD32F2F),
      colorDescription: 'Bright red (fresh) to dark brown (old)',
      severity: 'High',
      driveableNow: false,
      texture: 'Thin and oily',
      smell: 'Slightly sweet, faintly chemical',
      commonCauses: [
        'Cracked transmission pan',
        'Worn transmission pan gasket',
        'Damaged output shaft seal',
        'Cracked or loose ATF line',
      ],
      whatToDo:
          'Check transmission fluid level (if your car has a dipstick for it). Do not drive — low ATF causes expensive transmission damage.',
      beginnerExplanation:
          'Transmission fluid keeps your car\'s automatic gearbox working smoothly. Red puddle under the middle of the car often means this. Don\'t ignore it.',
      leakLocations: ['center', 'rear'],
    ),
    FluidLeak(
      id: 'power_steering',
      fluidType: 'Power Steering Fluid',
      typicalColor: Color(0xFF880E4F),
      colorDescription: 'Red to dark brown (similar to ATF)',
      severity: 'Medium',
      driveableNow: true,
      texture: 'Thin and oily',
      smell: 'Slightly sweet or burnt',
      commonCauses: [
        'Cracked power steering hose',
        'Worn pump seal',
        'Loose fitting on steering rack',
      ],
      whatToDo:
          'Check power steering reservoir level. Driveable carefully but steering will become heavy. Get the leak fixed soon.',
      beginnerExplanation:
          'This fluid makes turning the steering wheel easy. If it leaks out steering becomes very stiff, especially when parking.',
      leakLocations: ['front', 'center'],
    ),
    FluidLeak(
      id: 'washer_fluid',
      fluidType: 'Windshield Washer Fluid',
      typicalColor: Color(0xFF1565C0),
      colorDescription: 'Blue, green, or clear',
      severity: 'Low',
      driveableNow: true,
      texture: 'Watery',
      smell: 'Soap or alcohol scent',
      commonCauses: [
        'Cracked washer fluid reservoir',
        'Loose hose connection',
        'Frozen reservoir in winter',
      ],
      whatToDo: 'Not an emergency. Top up the washer fluid and find the crack or loose hose.',
      beginnerExplanation:
          'This is just windshield wiper fluid — it\'s not dangerous and your car will still drive fine without it. Top it up when you can.',
      leakLocations: ['front', 'anywhere'],
    ),
    FluidLeak(
      id: 'gear_oil',
      fluidType: 'Gear Oil (Manual Gearbox)',
      typicalColor: Color(0xFF1A1200),
      colorDescription: 'Very dark brown to black',
      severity: 'High',
      driveableNow: false,
      texture: 'Very thick and sticky',
      smell: 'Strong sulphur or rotten egg smell',
      commonCauses: [
        'Worn transmission seal',
        'Damaged gasket',
        'Cracked gearbox casing',
      ],
      whatToDo:
          'Do not drive. Low gear oil causes severe gearbox damage. Check level and have the leak repaired before driving.',
      beginnerExplanation:
          'This thick, very smelly fluid lubricates a manual gearbox. It has a distinctive strong smell. Running low destroys the gearbox.',
      leakLocations: ['center', 'rear'],
    ),
    FluidLeak(
      id: 'water',
      fluidType: 'Water (Normal Condensation)',
      typicalColor: Color(0xFFB3E5FC),
      colorDescription: 'Clear water',
      severity: 'Low',
      driveableNow: true,
      texture: 'Watery (no oil)',
      smell: 'No smell at all',
      commonCauses: [
        'Air conditioning condensation (completely normal in summer)',
        'Exhaust system condensation (normal when starting from cold)',
      ],
      whatToDo:
          'If it\'s clear water with no smell and comes from under the front on a hot day, it\'s just A/C condensation — completely normal.',
      beginnerExplanation:
          'Clear water under the car on a hot day is usually just condensation from the air conditioning — like how a cold drink sweats. Completely normal!',
      leakLocations: ['front', 'rear', 'anywhere'],
    ),
  ];
}
