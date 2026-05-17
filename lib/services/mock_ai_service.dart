import 'dart:math';
import '../models/scan_result.dart';

// Mock AI responses used when no API key is configured.
// Phase 3: this file is never touched for the live path — AiScanService routes there.
class MockAiService {
  static final _random = Random();

  static const List<Map<String, dynamic>> _parts = [
    {
      'partName': 'Brake Caliper',
      'estimatedPriceLow': 85.0,
      'estimatedPriceHigh': 200.0,
      'repairDifficulty': 'Intermediate',
      'explanation':
          'The component shows a cast-iron housing with a hydraulic piston bore and bleeder screw port. '
          'The sliding guide-pin design and dust-boot configuration are consistent with a front disc brake caliper assembly. '
          'The bracket mounting pattern suggests a single-piston floating caliper.',
      'fitmentWarning':
          'Calipers are side-specific (driver/passenger) and vary by rotor diameter. '
          'Confirm left vs. right side and rotor size using your VIN before ordering.',
      'suggestedSearchTerms': [
        'brake caliper replacement',
        'disc brake caliper',
        'caliper rebuild kit',
        'front brake caliper',
        'rear brake caliper',
      ],
      'safetyWarnings': [
        'Brake fluid is corrosive — avoid skin/eye contact and paint surfaces.',
        'Never let the caliper hang unsupported by the brake hose — it can damage the line.',
        'Always pump the brake pedal to firm before moving the vehicle after any brake work.',
        'Brakes are a safety-critical system — if unsure, have a qualified technician inspect the work.',
      ],
      'toolsNeeded': [
        'Floor jack & jack stands',
        'Lug wrench',
        '10 mm & 13 mm socket set',
        'C-clamp or caliper piston tool',
        'Brake-line wrench',
        'Catch pan for brake fluid',
      ],
      'repairSteps': [
        'Loosen lug nuts before jacking the vehicle.',
        'Safely lift and support the vehicle on jack stands.',
        'Remove the wheel.',
        'Locate the two caliper slide bolts and remove them.',
        'Pivot the caliper off the rotor — do not let it hang by the brake hose.',
        'Disconnect the brake hose and cap it to minimise fluid loss.',
        'Install the new caliper; torque mounting bolts to spec.',
        'Reconnect the brake hose and bleed the brake line.',
        'Reinstall the wheel and torque lug nuts to spec.',
        'Pump the brake pedal until firm before moving the vehicle.',
        'Test brakes at low speed in a safe area before driving normally.',
      ],
      'buyOptions': [
        {'store': 'AutoZone',      'priceRange': r'$89 – $175',  'url': 'autozone.com'},
        {'store': 'RockAuto',      'priceRange': r'$55 – $130',  'url': 'rockauto.com'},
        {'store': "O'Reilly Auto", 'priceRange': r'$95 – $185',  'url': 'oreillyauto.com'},
      ],
      'compatibleParts': [
        'OEM Replacement Caliper',
        'Rebuilt / Reman Caliper',
        'Performance Slotted Caliper',
      ],
    },
    {
      'partName': 'Alternator',
      'estimatedPriceLow': 120.0,
      'estimatedPriceHigh': 350.0,
      'repairDifficulty': 'Intermediate',
      'explanation':
          'The serpentine pulley, voltage regulator access cover, and three-phase stator housing indicate '
          'this is an automotive alternator. The B+ terminal stud and multi-pin connector are consistent '
          'with a late-model OEM Denso or Bosch-type unit.',
      'fitmentWarning':
          'Alternator amperage (80 A – 220 A) must match your vehicle\'s electrical load. '
          'Verify mounting bracket hole pattern and connector type against your OEM part number.',
      'suggestedSearchTerms': [
        'alternator replacement',
        'charging system repair',
        'reman alternator',
        'OEM alternator',
        'alternator bench test',
      ],
      'safetyWarnings': [
        'Always disconnect the NEGATIVE battery terminal first to prevent electrical shorts.',
        'The B+ cable carries battery voltage at all times — insulate it immediately after removal.',
        'A failing serpentine belt can damage the new alternator — inspect the belt while you have access.',
        'Verify charging voltage after installation — an overcharging alternator can damage electronics.',
      ],
      'toolsNeeded': [
        'Socket set (10 mm – 19 mm)',
        'Breaker bar',
        'Serpentine belt tool',
        'Battery tender / memory saver',
        'Multimeter',
      ],
      'repairSteps': [
        'Disconnect the NEGATIVE battery terminal first.',
        'Relieve serpentine belt tension and slide the belt off the alternator pulley.',
        'Disconnect the wiring harness connector and B+ cable.',
        'Remove the mounting bolts (usually 2 – 3).',
        'Compare the new alternator to the old one before installing.',
        'Install the new alternator and torque all bolts to spec.',
        'Re-route the serpentine belt.',
        'Reconnect all wiring and the battery terminal.',
        'Start the engine and verify charging voltage: 13.5 – 14.8 V with a multimeter.',
      ],
      'buyOptions': [
        {'store': 'AutoZone', 'priceRange': r'$130 – $280', 'url': 'autozone.com'},
        {'store': 'RockAuto', 'priceRange': r'$95 – $210',  'url': 'rockauto.com'},
        {'store': 'Amazon',   'priceRange': r'$110 – $300', 'url': 'amazon.com'},
      ],
      'compatibleParts': [
        'OEM Alternator',
        'Remanufactured Alternator',
        'High-Output Alternator (200 A+)',
      ],
    },
    {
      'partName': 'Oxygen Sensor',
      'estimatedPriceLow': 25.0,
      'estimatedPriceHigh': 100.0,
      'repairDifficulty': 'Beginner',
      'explanation':
          'The ceramic sensing element, protective louvers, and hex-body thread profile are characteristic '
          'of a wideband or narrowband exhaust oxygen sensor. The four-wire heated design and connector '
          'pigtail suggest an upstream (pre-catalytic converter) fitment.',
      'fitmentWarning':
          'O2 sensor position (upstream vs. downstream) and thread pitch (M18 × 1.5 is most common) '
          'must match exactly. Confirm bank and sensor number using your OBD-II codes and a wiring diagram.',
      'suggestedSearchTerms': [
        'upstream oxygen sensor',
        'downstream O2 sensor',
        'heated oxygen sensor HO2S',
        'wideband AFR sensor',
        'check engine P0141',
      ],
      'safetyWarnings': [
        'Exhaust components stay dangerously hot long after the engine is off — wait at least 1 hour.',
        'Do not apply anti-seize to the sensing element tip — only to the threads.',
        'Forcing a cold, seized sensor can break it off in the bung, requiring extraction tools.',
        'Clearing codes without a full drive cycle will give a false "pass" on emissions tests.',
      ],
      'toolsNeeded': [
        'O2 sensor socket (3/8" drive)',
        'Ratchet & extension',
        'Penetrating oil (PB Blaster or WD-40)',
        'OBD-II scanner to clear codes',
      ],
      'repairSteps': [
        'Confirm the faulty sensor using an OBD-II scanner (common codes: P0130–P0167).',
        'Allow the exhaust to cool completely — minimum 1 hour.',
        'Spray penetrating oil on the sensor threads; wait 15 minutes.',
        'Use the O2 sensor socket to unscrew the old sensor — do not force it cold.',
        'Apply anti-seize to the new sensor threads (skip if pre-applied).',
        'Thread in by hand first; torque to 30 – 40 ft-lbs.',
        'Reconnect the wiring connector.',
        'Clear OBD codes and verify the check-engine light stays off after a full drive cycle.',
      ],
      'buyOptions': [
        {'store': 'AutoZone',  'priceRange': r'$30 – $95',  'url': 'autozone.com'},
        {'store': 'RockAuto',  'priceRange': r'$18 – $75',  'url': 'rockauto.com'},
        {'store': 'NAPA Auto', 'priceRange': r'$35 – $100', 'url': 'napaonline.com'},
      ],
      'compatibleParts': [
        'Upstream (pre-cat) O2 Sensor',
        'Downstream (post-cat) O2 Sensor',
        'Wideband / AFR Sensor',
      ],
    },
    {
      'partName': 'Radiator',
      'estimatedPriceLow': 150.0,
      'estimatedPriceHigh': 450.0,
      'repairDifficulty': 'Advanced',
      'explanation':
          'The aluminium core with plastic end tanks, inlet/outlet pipe stubs, and integrated transmission '
          'cooler port lines are consistent with a direct-fit OEM-style radiator. Visible fin damage or '
          'green/orange coolant staining indicates an active leak.',
      'fitmentWarning':
          'Radiator core width, height, and inlet/outlet pipe positions vary significantly by engine and '
          'trim level. Cross-reference the OEM part number using your VIN — a wrong-size radiator will '
          'not seat in the support brackets.',
      'suggestedSearchTerms': [
        'radiator replacement',
        'coolant leak repair',
        'aluminium radiator',
        'direct fit radiator',
        'cooling system flush',
      ],
      'safetyWarnings': [
        'NEVER open a hot radiator cap — pressurised coolant causes severe scalding burns.',
        'Coolant (ethylene glycol) is toxic to pets and wildlife — collect and dispose properly.',
        'Overfilling coolant can damage the overflow reservoir and cause leaks.',
        'Air pockets in the cooling system will cause overheating — follow the bleed procedure exactly.',
      ],
      'toolsNeeded': [
        'Large drain pan (2 + gallons)',
        'Hose-clamp pliers',
        'Socket set',
        'Coolant flush kit',
        'Fresh 50/50 coolant mix',
        'Flashlight',
      ],
      'repairSteps': [
        'Let the engine cool completely — minimum 2 hours.',
        'Place a drain pan under the radiator petcock; open it to drain coolant.',
        'Dispose of old coolant at an approved recycling centre — it is toxic to animals.',
        'Remove the upper and lower radiator hoses.',
        'Disconnect transmission cooler lines if applicable — have rags ready.',
        'Unbolt and remove the cooling fan shroud.',
        'Unbolt the radiator mounting brackets and lift out the old radiator carefully.',
        'Install the new radiator and secure mounting brackets.',
        'Reconnect hoses, cooler lines, and the fan shroud.',
        'Fill with fresh 50/50 coolant and bleed trapped air per the manufacturer procedure.',
        'Run the engine to operating temperature; check for leaks at all connections.',
      ],
      'buyOptions': [
        {'store': 'AutoZone',     'priceRange': r'$160 – $420', 'url': 'autozone.com'},
        {'store': 'RockAuto',     'priceRange': r'$110 – $360', 'url': 'rockauto.com'},
        {'store': 'CarParts.com', 'priceRange': r'$140 – $400', 'url': 'carparts.com'},
      ],
      'compatibleParts': [
        'OEM Direct-Fit Radiator',
        'Aluminum Performance Radiator',
        'Heavy-Duty Towing Radiator',
      ],
    },
    {
      'partName': 'Starter Motor',
      'estimatedPriceLow': 100.0,
      'estimatedPriceHigh': 280.0,
      'repairDifficulty': 'Intermediate',
      'explanation':
          'The compact gear-reduction housing, solenoid plunger cap, and armature commutator end indicate '
          'this is an automotive starter motor. The pinion gear and overrunning clutch assembly engage the '
          'ring gear on the flywheel/flexplate to crank the engine.',
      'fitmentWarning':
          'Starter motors vary by engine displacement, transmission type (auto vs. manual), and mounting '
          'hole pattern. Verify the number of mounting bolts and their position matches your application.',
      'suggestedSearchTerms': [
        'starter motor replacement',
        'starter solenoid repair',
        'no crank diagnosis',
        'gear reduction starter',
        'high torque starter',
      ],
      'safetyWarnings': [
        'Disconnect the NEGATIVE battery terminal before touching any wiring near the starter.',
        'The starter solenoid main terminal is live even with the ignition off — insulate it immediately.',
        'Do not crank the engine for more than 10 seconds at a time to prevent starter overheating.',
        'Ensure the transmission is in Park (auto) or Neutral with the parking brake set before testing.',
      ],
      'toolsNeeded': [
        'Socket set (10 mm – 19 mm)',
        'Combination wrench set',
        'Floor jack (if starter is underneath)',
        'Safety glasses & gloves',
        'Torque wrench',
      ],
      'repairSteps': [
        'Disconnect the NEGATIVE battery terminal.',
        'Locate the starter — typically at the bottom of the engine near the transmission bell housing.',
        'Raise and support the vehicle on jack stands if needed for access.',
        'Label all wires connected to the starter solenoid, then disconnect them.',
        'Remove the mounting bolts (usually 2 – 3).',
        'Compare the replacement starter to the old one to confirm identical fitment.',
        'Install the new starter and torque mounting bolts to spec.',
        'Reconnect all wiring in the reverse order you removed it.',
        'Reconnect the battery terminal and test crank.',
      ],
      'buyOptions': [
        {'store': 'AutoZone',      'priceRange': r'$110 – $260', 'url': 'autozone.com'},
        {'store': 'RockAuto',      'priceRange': r'$70 – $200',  'url': 'rockauto.com'},
        {'store': "O'Reilly Auto", 'priceRange': r'$120 – $270', 'url': 'oreillyauto.com'},
      ],
      'compatibleParts': [
        'OEM Starter',
        'Remanufactured Starter',
        'High-Torque Gear-Reduction Starter',
      ],
    },
  ];

  static Future<ScanResult> analyze({
    required String imagePath,
    required String year,
    required String make,
    required String model,
    required String trim,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final data        = _parts[_random.nextInt(_parts.length)];
    final confidence  = 0.72 + _random.nextDouble() * 0.25;
    final vehicleInfo = '$year $make $model — $trim';
    final priceLow    = data['estimatedPriceLow']  as double;
    final priceHigh   = data['estimatedPriceHigh'] as double;

    final buyOptions = (data['buyOptions'] as List)
        .map((b) => BuyOption(
              store:      b['store']      as String,
              priceRange: b['priceRange'] as String,
              url:        b['url']        as String,
            ))
        .toList();

    return ScanResult(
      id:                   DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath:            imagePath,
      partName:             data['partName']        as String,
      confidenceScore:      confidence,
      priceEstimate:        '\$${priceLow.toStringAsFixed(0)} – \$${priceHigh.toStringAsFixed(0)}',
      estimatedPriceLow:    priceLow,
      estimatedPriceHigh:   priceHigh,
      repairDifficulty:     data['repairDifficulty']   as String,
      explanation:          data['explanation']        as String,
      fitmentWarning:       data['fitmentWarning']     as String,
      suggestedSearchTerms: List<String>.from(data['suggestedSearchTerms'] as List),
      safetyWarnings:       List<String>.from(data['safetyWarnings']       as List),
      toolsNeeded:          List<String>.from(data['toolsNeeded']          as List),
      repairSteps:          List<String>.from(data['repairSteps']          as List),
      buyOptions:           buyOptions,
      compatibleParts:      List<String>.from(data['compatibleParts']      as List),
      scannedAt:            DateTime.now(),
      vehicleInfo:          vehicleInfo,
    );
  }
}
