import '../models/visual_part.dart';
import 'ai_scan_service.dart';

class VisualIdService {
  static Future<VisualPartResult> identify({
    required String imagePath,
    required String year,
    required String make,
    required String model,
    required String trim,
  }) async {
    final analysis = await AiScanService.analyze(
      imagePath: imagePath,
      year: year,
      make: make,
      model: model,
      trim: trim,
    );

    final scan = analysis.result;
    final enrichment = _enrich(scan.partName);

    return VisualPartResult(
      partName:            scan.partName,
      whatItDoes:          enrichment['whatItDoes'] as String,
      beginnerExplanation: enrichment['beginnerExplanation'] as String,
      symptoms:            enrichment['symptoms'] as List<String>,
      urgency:             _urgencyFromDifficulty(scan.repairDifficulty),
      priceRange:          scan.priceRange,
      diyDifficulty:       scan.repairDifficulty,
      videoSearchTerms:    scan.suggestedSearchTerms.isNotEmpty
          ? scan.suggestedSearchTerms
          : ['${scan.partName} replacement', '${scan.partName} symptoms', 'how to replace ${scan.partName}'],
      safetyWarnings:      scan.safetyWarnings.isNotEmpty
          ? scan.safetyWarnings
          : _defaultSafetyWarnings,
      confidence:          scan.confidenceScore,
      imagePath:           imagePath,
      identifiedAt:        DateTime.now(),
    );
  }

  static String _urgencyFromDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Advanced':     return 'High';
      case 'Intermediate': return 'Medium';
      default:             return 'Low';
    }
  }

  static const _defaultSafetyWarnings = [
    'AI identification may be incorrect — always verify with a qualified mechanic.',
    'Do not attempt repairs beyond your skill level.',
    'Disconnect the battery before working on electrical components.',
    'Always use wheel chocks and jack stands — never rely on a hydraulic jack alone.',
  ];

  // Provides richer information for common identified parts.
  // Falls back to generic descriptions for unknown parts.
  static Map<String, dynamic> _enrich(String partName) {
    final key = partName.toLowerCase();
    for (final entry in _enrichmentDb.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return {
      'whatItDoes': 'This component is part of your vehicle\'s mechanical or electrical system.',
      'beginnerExplanation':
          'Your AI assistant identified this part. Consult the owner\'s manual or a mechanic for more specific information.',
      'symptoms': ['Unusual noises', 'Warning lights', 'Performance changes'],
    };
  }

  static final _enrichmentDb = <String, Map<String, dynamic>>{
    'air filter': {
      'whatItDoes':
          'Removes dirt, dust, and debris from incoming air before it enters the engine. A clogged filter starves the engine of clean air, reducing performance and fuel economy.',
      'beginnerExplanation':
          'Think of it like a face mask for your engine — it keeps dirt out. When it gets too clogged, the engine can\'t breathe properly.',
      'symptoms': [
        'Reduced fuel economy (5–15% worse)',
        'Sluggish acceleration',
        'Rough idle or engine misfires',
        'Black smoke from exhaust',
        'Engine making unusual sounds',
      ],
    },
    'oil filter': {
      'whatItDoes':
          'Removes metal particles, dirt, and combustion byproducts from engine oil, keeping it clean as it circulates through the engine.',
      'beginnerExplanation':
          'Like a coffee filter for your engine oil — it catches all the gunk so clean oil keeps lubricating the engine.',
      'symptoms': [
        'Decreased oil pressure',
        'Metallic contaminants in oil',
        'Engine running rough',
        'Increased engine wear over time',
      ],
    },
    'brake pad': {
      'whatItDoes':
          'Brake pads press against the brake rotor (disc) to create friction that slows the vehicle. They are consumable components that wear down over time.',
      'beginnerExplanation':
          'Brake pads are the things that squeeze against a metal disc to stop your car. When they\'re worn thin they squeal — that\'s your car begging for new ones.',
      'symptoms': [
        'Squealing or squeaking when braking',
        'Grinding metal-on-metal noise',
        'Longer stopping distances',
        'Brake pedal vibrating',
        'Vehicle pulling to one side when braking',
      ],
    },
    'serpentine belt': {
      'whatItDoes':
          'A single continuous belt that powers the alternator, power steering pump, air conditioning compressor, and water pump. If it fails, all those systems stop.',
      'beginnerExplanation':
          'One rubber belt that runs everything — if it snaps while driving your steering, charging, A/C, and cooling all stop at once.',
      'symptoms': [
        'Loud squealing from engine bay',
        'Battery warning light',
        'Power steering suddenly heavy',
        'A/C stops working',
        'Engine overheating',
      ],
    },
    'alternator': {
      'whatItDoes':
          'Converts mechanical energy from the engine into electrical energy to charge the battery and power all electrical systems while the engine is running.',
      'beginnerExplanation':
          'It\'s the battery charger built into your car. While the engine runs, it keeps the battery full. If it fails, you\'ll be running on battery power only until the car dies.',
      'symptoms': [
        'Battery warning light on dashboard',
        'Dim or flickering headlights',
        'Electrical accessories malfunctioning',
        'Dead battery repeatedly',
        'Burning rubber smell',
      ],
    },
    'battery': {
      'whatItDoes':
          'Stores electrical energy and provides the high-current burst needed to start the engine. Also stabilises voltage for sensitive electronics.',
      'beginnerExplanation':
          'Like the battery in a remote control but much bigger. It starts the car and keeps the clock/radio working when the engine is off.',
      'symptoms': [
        'Car won\'t start or cranks slowly',
        'Clicking sound when turning key',
        'Battery warning light',
        'Electrical systems behaving oddly',
        'Swollen or bloated battery case',
      ],
    },
    'radiator': {
      'whatItDoes':
          'Dissipates heat from engine coolant by flowing it through thin metal tubes past which air passes, cooling the liquid before it returns to the engine.',
      'beginnerExplanation':
          'Like a big flat sieve at the front of the car — hot coolant flows through tiny tubes and the air rushing past cools it down.',
      'symptoms': [
        'Engine overheating',
        'Coolant leaking under front of car',
        'Sweet antifreeze smell',
        'Steam from engine bay',
        'Temperature gauge high',
      ],
    },
    'spark plug': {
      'whatItDoes':
          'Produces the electrical spark that ignites the air-fuel mixture in each cylinder at precisely the right moment. Each cylinder has one spark plug.',
      'beginnerExplanation':
          'Like a tiny lighter inside each cylinder — it makes a spark that ignites the fuel to make the engine run.',
      'symptoms': [
        'Engine misfiring or rough running',
        'Poor fuel economy',
        'Difficulty starting',
        'Lack of acceleration',
        'Check Engine light',
      ],
    },
    'thermostat': {
      'whatItDoes':
          'Controls coolant flow from the engine to the radiator based on temperature. It keeps the engine at its optimal operating temperature — not too cold, not too hot.',
      'beginnerExplanation':
          'Like a temperature valve — it blocks coolant until the engine warms up, then opens to let cooling happen.',
      'symptoms': [
        'Engine overheating quickly',
        'Engine running permanently cold',
        'Heater not producing warm air',
        'Temperature gauge fluctuating',
        'Coolant leaking near thermostat housing',
      ],
    },
    'water pump': {
      'whatItDoes':
          'Circulates coolant throughout the engine and through the radiator continuously. Without it, coolant would sit still and the engine would overheat in minutes.',
      'beginnerExplanation':
          'Think of it as the heart of the cooling system — it pumps coolant around like your heart pumps blood.',
      'symptoms': [
        'Engine overheating',
        'Coolant leaking under middle of engine',
        'Grinding or whining noise from engine',
        'Steam from engine bay',
      ],
    },
    'fuel filter': {
      'whatItDoes':
          'Removes debris and contaminants from fuel before it reaches the engine\'s fuel injectors. A clogged filter restricts fuel flow and hurts performance.',
      'beginnerExplanation':
          'A small filter in the fuel line that keeps dirt from reaching the engine. Like a water filter but for petrol/diesel.',
      'symptoms': [
        'Hard to start',
        'Sputtering or hesitation when accelerating',
        'Engine stalling',
        'Reduced power at high speed',
      ],
    },
    'oxygen sensor': {
      'whatItDoes':
          'Measures the amount of oxygen in exhaust gases and feeds that data to the engine computer, which adjusts the fuel mixture for optimal combustion efficiency.',
      'beginnerExplanation':
          'A sensor that sniffs the exhaust to check if the engine is burning fuel correctly. If it\'s wrong, the engine wastes fuel.',
      'symptoms': [
        'Check Engine light',
        'Poor fuel economy (10–40% worse)',
        'Rough idle',
        'Failed emissions test',
        'Engine running rich (smell of fuel)',
      ],
    },
    'cv joint': {
      'whatItDoes':
          'Constant Velocity joints transfer power from the transmission to the drive wheels while allowing the suspension to move up and down and the wheels to steer.',
      'beginnerExplanation':
          'The bendy joint that lets power reach your front wheels even when they\'re turning and the suspension is moving.',
      'symptoms': [
        'Clicking or popping noise when turning',
        'Vibration when accelerating',
        'Grease on inside of wheel',
        'Clunking on acceleration from stop',
      ],
    },
    'tie rod': {
      'whatItDoes':
          'Connects the steering rack to the steering knuckle at each wheel, translating steering inputs into wheel movement. Critical for directional control.',
      'beginnerExplanation':
          'The metal rod that connects the steering wheel mechanism to the actual wheels. If it breaks, you lose steering control.',
      'symptoms': [
        'Loose or wandering steering',
        'Uneven or rapid tyre wear',
        'Clunking sound when steering',
        'Vehicle pulling to one side',
        'Vibration in steering wheel',
      ],
    },
    'starter': {
      'whatItDoes':
          'An electric motor that cranks the engine over at start-up, allowing the pistons to move fast enough for the engine to fire and run on its own.',
      'beginnerExplanation':
          'The motor that gets your engine spinning when you turn the key. Once the engine is running it disengages automatically.',
      'symptoms': [
        'Clicking sound but engine won\'t turn over',
        'Grinding noise on start-up',
        'Car won\'t start despite good battery',
        'Starter motor spinning without engaging engine',
      ],
    },
  };
}
