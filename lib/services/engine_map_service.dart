import 'package:flutter/material.dart';
import '../models/engine_component.dart';

class EngineMapService {
  static List<EngineComponent> get components => _components;

  static const _components = <EngineComponent>[
    EngineComponent(
      id: 'radiator',
      name: 'Radiator',
      shortDescription: 'Keeps engine cool',
      whatItDoes:
          'The radiator dissipates heat from engine coolant by passing it through thin metal fins where air can cool it. It is essentially the engine\'s heat exchanger.',
      beginnerExplanation:
          'Think of it like a big flat sieve at the front of the engine — hot liquid runs through it, the moving air cools it down.',
      relX: 0.50, relY: 0.08,
      failureRisk: 'Medium',
      dotColor: Color(0xFFFFB800),
      symptoms: ['Engine overheating', 'Coolant leaking from front', 'Sweet smell from front of car'],
      maintenanceTip: 'Flush and replace coolant every 2–5 years. Inspect hoses annually for cracks.',
    ),
    EngineComponent(
      id: 'battery',
      name: 'Battery',
      shortDescription: 'Stores electrical power',
      whatItDoes:
          'The battery provides the burst of electricity needed to start the engine and powers all electronics when the engine is off.',
      beginnerExplanation:
          'Like a giant phone battery for your car. It starts the engine and keeps the radio/lights on when the engine isn\'t running.',
      relX: 0.82, relY: 0.18,
      failureRisk: 'High',
      dotColor: Color(0xFFFF3B30),
      symptoms: ['Car won\'t start', 'Slow cranking', 'Clicking noise when turning key', 'Dim headlights'],
      maintenanceTip: 'Test battery health annually. Most car batteries last 3–5 years.',
    ),
    EngineComponent(
      id: 'air_filter',
      name: 'Air Filter / Intake',
      shortDescription: 'Filters air into engine',
      whatItDoes:
          'The air filter removes dust, pollen, and debris from the air before it enters the engine. Clean air is essential for efficient combustion.',
      beginnerExplanation:
          'Like a nose hair filter for your engine. It stops dirt from getting into the engine and damaging it. Needs replacing like a vacuum filter.',
      relX: 0.15, relY: 0.22,
      failureRisk: 'Low',
      dotColor: Color(0xFF00E676),
      symptoms: ['Reduced fuel economy', 'Sluggish acceleration', 'Black smoke from exhaust', 'Rough idle'],
      maintenanceTip: 'Replace every 15,000–30,000 miles or as per manufacturer schedule.',
    ),
    EngineComponent(
      id: 'alternator',
      name: 'Alternator',
      shortDescription: 'Charges battery while driving',
      whatItDoes:
          'The alternator is a generator driven by the engine. It converts mechanical energy into electricity to charge the battery and power all electrical systems while driving.',
      beginnerExplanation:
          'It\'s the charger for your car\'s battery. While the engine runs, it keeps the battery topped up so your car doesn\'t die.',
      relX: 0.72, relY: 0.38,
      failureRisk: 'Medium',
      dotColor: Color(0xFFFFB800),
      symptoms: ['Battery warning light', 'Dim/flickering lights', 'Dead battery repeatedly', 'Whining noise from engine'],
      maintenanceTip: 'The alternator typically lasts 7–10 years. Replace the drive belt at service intervals.',
    ),
    EngineComponent(
      id: 'serpentine_belt',
      name: 'Serpentine Belt',
      shortDescription: 'Drives engine accessories',
      whatItDoes:
          'A single continuous belt that drives the alternator, power steering pump, A/C compressor, and water pump. If it breaks, all these systems stop simultaneously.',
      beginnerExplanation:
          'One long rubber belt that drives almost everything in the engine bay. If it snaps, your power steering, battery charging, and cooling all stop at once.',
      relX: 0.52, relY: 0.42,
      failureRisk: 'High',
      dotColor: Color(0xFFFF3B30),
      symptoms: ['Loud squealing from engine', 'A/C stops working', 'Battery light on', 'Power steering lost'],
      maintenanceTip: 'Replace every 60,000–100,000 miles. Inspect for cracks and fraying annually.',
    ),
    EngineComponent(
      id: 'engine_block',
      name: 'Engine Block',
      shortDescription: 'Heart of the engine',
      whatItDoes:
          'The engine block is the main structure housing the cylinders, pistons, and crankshaft. Combustion of fuel and air in the cylinders drives the pistons which turn the crankshaft to produce power.',
      beginnerExplanation:
          'This is the core of your car\'s engine — where fuel is burned to make the car move. It\'s the most expensive part to repair.',
      relX: 0.50, relY: 0.50,
      failureRisk: 'Low',
      dotColor: Color(0xFF00B4FF),
      symptoms: ['Major oil leaks', 'Loss of compression', 'Severe knocking noise', 'White smoke from exhaust'],
      maintenanceTip: 'Regular oil changes are the single most important thing you can do to protect the engine block.',
    ),
    EngineComponent(
      id: 'oil_cap',
      name: 'Oil Filler Cap',
      shortDescription: 'Where you add engine oil',
      whatItDoes:
          'The oil filler cap seals the valve cover and is the access point for adding engine oil. It often has a dipstick nearby for checking oil level.',
      beginnerExplanation:
          'This is where you pour in new oil. It\'s usually a black cap on top of the engine with an oil can symbol on it.',
      relX: 0.38, relY: 0.44,
      failureRisk: 'Low',
      dotColor: Color(0xFF00E676),
      symptoms: ['Oil leaking from cap area', 'Oil mist under hood', 'Low oil level'],
      maintenanceTip: 'Check oil level monthly. Change oil every 3,000–7,500 miles depending on oil type.',
    ),
    EngineComponent(
      id: 'coolant_reservoir',
      name: 'Coolant Reservoir',
      shortDescription: 'Stores extra coolant',
      whatItDoes:
          'The coolant overflow reservoir catches expanding coolant from the radiator. It allows the cooling system to maintain pressure and recycles coolant back when it cools.',
      beginnerExplanation:
          'A see-through plastic bottle near the radiator. You can see the coolant level without opening anything — just check between the MIN and MAX marks.',
      relX: 0.82, relY: 0.52,
      failureRisk: 'Low',
      dotColor: Color(0xFF00E676),
      symptoms: ['Coolant level dropping repeatedly', 'Overheating', 'Sweet smell'],
      maintenanceTip: 'Check coolant level monthly. Top up only with the correct coolant type for your vehicle.',
    ),
    EngineComponent(
      id: 'power_steering',
      name: 'Power Steering Pump/Reservoir',
      shortDescription: 'Makes steering easy',
      whatItDoes:
          'The power steering pump pressurises hydraulic fluid to assist with turning the steering wheel. Many newer cars use electric power steering and have no fluid reservoir.',
      beginnerExplanation:
          'This makes turning your steering wheel easy. Without it you\'d need to use a lot of force to turn, especially when parking.',
      relX: 0.18, relY: 0.52,
      failureRisk: 'Medium',
      dotColor: Color(0xFFFFB800),
      symptoms: ['Heavy/stiff steering', 'Whining noise when turning', 'Red/brown fluid leak near front'],
      maintenanceTip: 'Check fluid level periodically. If you have electric power steering, no fluid to check.',
    ),
    EngineComponent(
      id: 'water_pump',
      name: 'Water Pump',
      shortDescription: 'Circulates coolant',
      whatItDoes:
          'The water pump circulates coolant through the engine and radiator, keeping everything at the right temperature. It is driven by the timing belt or serpentine belt.',
      beginnerExplanation:
          'Think of it as the heart of your cooling system — it pumps coolant around the engine the way your heart pumps blood.',
      relX: 0.36, relY: 0.56,
      failureRisk: 'Medium',
      dotColor: Color(0xFFFFB800),
      symptoms: ['Coolant leaking near center of engine', 'Overheating', 'Grinding noise from engine'],
      maintenanceTip: 'Replace at timing belt service intervals — typically every 60,000–100,000 miles.',
    ),
    EngineComponent(
      id: 'brake_master',
      name: 'Brake Master Cylinder',
      shortDescription: 'Converts pedal to brake pressure',
      whatItDoes:
          'When you press the brake pedal, the master cylinder converts that force into hydraulic pressure which travels through brake lines to clamp the brakes at each wheel.',
      beginnerExplanation:
          'This is what turns pressing the brake pedal into actual stopping force. If it fails, your brakes won\'t work at all.',
      relX: 0.15, relY: 0.68,
      failureRisk: 'Medium',
      dotColor: Color(0xFFFF3B30),
      symptoms: ['Spongy or soft brake pedal', 'Brake pedal sinks to floor', 'Fluid leak near firewall', 'Brake warning light'],
      maintenanceTip: 'Change brake fluid every 2 years. The master cylinder typically lasts the life of the car if fluid is maintained.',
    ),
    EngineComponent(
      id: 'fuse_box',
      name: 'Fuse Box',
      shortDescription: 'Protects electrical circuits',
      whatItDoes:
          'The fuse box contains fuses and relays that protect electrical circuits. When a circuit is overloaded, the fuse blows and breaks the circuit to prevent fire or damage.',
      beginnerExplanation:
          'Like the circuit breaker panel in your home — if an electrical thing stops working (radio, lights, wipers), a blown fuse is often why.',
      relX: 0.80, relY: 0.70,
      failureRisk: 'Low',
      dotColor: Color(0xFF00E676),
      symptoms: ['Electrical system stopped working', 'Specific accessory not working', 'Interior lights not working'],
      maintenanceTip: 'Check the fuse box diagram on the cover before replacing fuses. Always replace with the correct amperage.',
    ),
  ];
}
