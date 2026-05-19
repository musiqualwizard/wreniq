import 'package:flutter/material.dart';
import '../models/warning_light.dart';

class WarningLightService {
  static List<WarningLight> get all => _lights;

  static List<WarningLight> byCategory(String category) =>
      _lights.where((l) => l.category == category).toList();

  static List<String> get categories =>
      ['Engine', 'Safety', 'Fluid', 'Electrical', 'Tires'];

  static const _lights = <WarningLight>[
    WarningLight(
      id: 'check_engine',
      name: 'Check Engine',
      icon: Icons.settings_outlined,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: true,
      category: 'Engine',
      whatItMeans:
          'The engine control module detected a fault — could be anything from a loose gas cap to a misfiring cylinder.',
      whatToDo:
          'Get the fault code read at any auto parts store (free). Do not ignore it for long — a blinking light means stop driving immediately.',
      beginnerExplanation:
          'Think of it like your car\'s "something is wrong" alarm. It could be minor (loose fuel cap) or serious. Getting the code read is free at AutoZone.',
    ),
    WarningLight(
      id: 'oil_pressure',
      name: 'Oil Pressure',
      icon: Icons.opacity,
      color: Color(0xFFFF3B30),
      severity: 'Critical',
      safeToRide: false,
      category: 'Fluid',
      whatItMeans:
          'Engine oil pressure has dropped dangerously low. Continuing to drive will cause severe and permanent engine damage within minutes.',
      whatToDo:
          'Pull over IMMEDIATELY. Turn the engine off. Check oil level with the dipstick. Do not restart until the cause is found.',
      beginnerExplanation:
          'Oil is what keeps your engine from destroying itself. No oil pressure = engine seizes. Stop the car NOW.',
    ),
    WarningLight(
      id: 'temperature',
      name: 'Engine Temperature',
      icon: Icons.thermostat,
      color: Color(0xFFFF3B30),
      severity: 'Critical',
      safeToRide: false,
      category: 'Engine',
      whatItMeans:
          'Coolant temperature is critically high. Your engine is overheating and may sustain permanent damage if you keep driving.',
      whatToDo:
          'Pull over safely, turn off the A/C, open windows. If the gauge keeps rising, turn the engine off. Never open the radiator cap on a hot engine.',
      beginnerExplanation:
          'Your engine is getting way too hot. Imagine running a marathon with no water — engines overheat and break too. Pull over and let it cool down.',
    ),
    WarningLight(
      id: 'battery',
      name: 'Battery / Charging',
      icon: Icons.battery_alert,
      color: Color(0xFFFF3B30),
      severity: 'Warning',
      safeToRide: true,
      category: 'Electrical',
      whatItMeans:
          'The charging system is not maintaining proper voltage. The alternator may have failed or there is a loose belt/connection.',
      whatToDo:
          'Drive to a mechanic or parts store soon. Your car is running on battery power only and will shut down when the battery dies.',
      beginnerExplanation:
          'Your car\'s battery charger (called an alternator) may have stopped working. Your car will die soon — head to a shop.',
    ),
    WarningLight(
      id: 'brake_system',
      name: 'Brake System',
      icon: Icons.circle_outlined,
      color: Color(0xFFFF3B30),
      severity: 'Critical',
      safeToRide: false,
      category: 'Safety',
      whatItMeans:
          'Brake system fault detected. This could mean low brake fluid, worn pads, or a hydraulic failure.',
      whatToDo:
          'Check if the parking brake is accidentally on first. If not — do not drive. Have it towed or inspected before driving.',
      beginnerExplanation:
          'Your brakes might not work properly. This is extremely dangerous — do not drive until a mechanic checks it.',
    ),
    WarningLight(
      id: 'abs',
      name: 'ABS',
      icon: Icons.adjust,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: true,
      category: 'Safety',
      whatItMeans:
          'The Anti-lock Braking System has a fault. Normal braking still works but ABS (which prevents skidding) is disabled.',
      whatToDo:
          'You can drive carefully, but avoid hard braking on slippery surfaces. Get it diagnosed soon.',
      beginnerExplanation:
          'ABS stops your wheels from locking up when you brake hard on slippery roads. It\'s off for now, so brake more gently.',
    ),
    WarningLight(
      id: 'airbag',
      name: 'Airbag / SRS',
      icon: Icons.face,
      color: Color(0xFFFF3B30),
      severity: 'Warning',
      safeToRide: true,
      category: 'Safety',
      whatItMeans:
          'The Supplemental Restraint System (airbags and seat belt pretensioners) has a fault and may not deploy in a crash.',
      whatToDo:
          'Get it diagnosed by a mechanic. Airbags require a specialist — do not attempt DIY repair.',
      beginnerExplanation:
          'Your airbags might not open in a crash. The car is drivable but you have less protection. Get it fixed soon.',
    ),
    WarningLight(
      id: 'traction_control',
      name: 'Traction Control Off',
      icon: Icons.waves,
      color: Color(0xFFFFB800),
      severity: 'Info',
      safeToRide: true,
      category: 'Safety',
      whatItMeans:
          'Traction control system is either disabled manually or has a fault. Wheel spin on slippery surfaces is less controlled.',
      whatToDo:
          'Check if you accidentally pressed the TCS button. If it came on by itself, get it scanned.',
      beginnerExplanation:
          'Traction control helps prevent your wheels from spinning out. It\'s off right now so drive carefully on wet or icy roads.',
    ),
    WarningLight(
      id: 'tire_pressure',
      name: 'Tire Pressure (TPMS)',
      icon: Icons.tire_repair,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: true,
      category: 'Tires',
      whatItMeans:
          'One or more tires is significantly under-inflated (usually 25% below recommended pressure).',
      whatToDo:
          'Check all tire pressures at a gas station. Recommended pressure is on the sticker inside the driver\'s door jamb.',
      beginnerExplanation:
          'At least one of your tires needs air. Low tires waste fuel and can blow out at highway speed. Add air ASAP.',
    ),
    WarningLight(
      id: 'low_fuel',
      name: 'Low Fuel',
      icon: Icons.local_gas_station,
      color: Color(0xFFFFB800),
      severity: 'Info',
      safeToRide: true,
      category: 'Fluid',
      whatItMeans: 'Fuel level is critically low (typically under 10–15% remaining).',
      whatToDo: 'Refuel as soon as possible. Running out completely can damage the fuel pump.',
      beginnerExplanation:
          'You\'re almost out of gas! Get to a gas station soon. Running out can damage parts inside the fuel tank.',
    ),
    WarningLight(
      id: 'power_steering',
      name: 'Power Steering',
      icon: Icons.settings_input_antenna,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: true,
      category: 'Fluid',
      whatItMeans:
          'Power steering system fault. Steering may become very heavy, especially at low speeds or when parking.',
      whatToDo:
          'Check power steering fluid level. If fluid is fine, have the system inspected. The car is drivable but steering is harder.',
      beginnerExplanation:
          'Power steering makes it easy to turn the wheel. Without it, steering feels like wrestling. It still works but needs much more effort.',
    ),
    WarningLight(
      id: 'transmission',
      name: 'Transmission Temp',
      icon: Icons.thermostat_auto,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: false,
      category: 'Engine',
      whatItMeans:
          'Automatic transmission fluid is overheating. Continuing to drive risks serious transmission damage.',
      whatToDo:
          'Pull over and let the transmission cool for 30–60 minutes. Avoid towing or performance driving afterwards.',
      beginnerExplanation:
          'Your transmission (the thing that changes gears) is overheating. Pull over and rest — it\'s like letting your phone cool down after it gets hot.',
    ),
    WarningLight(
      id: 'service_required',
      name: 'Service Required',
      icon: Icons.build_outlined,
      color: Color(0xFFFFB800),
      severity: 'Info',
      safeToRide: true,
      category: 'Engine',
      whatItMeans:
          'Scheduled maintenance interval is due — usually oil change, tire rotation, or inspection.',
      whatToDo: 'Book a routine service appointment. Not an emergency but should not be postponed indefinitely.',
      beginnerExplanation:
          'Think of this like a "tune-up reminder." Your car is telling you it needs its regular checkup — like a doctor\'s appointment.',
    ),
    WarningLight(
      id: 'fuel_cap',
      name: 'Loose Fuel Cap',
      icon: Icons.lock_open,
      color: Color(0xFFFFB800),
      severity: 'Info',
      safeToRide: true,
      category: 'Engine',
      whatItMeans:
          'Fuel system is not sealed. Usually caused by a loose or missing gas cap, which allows fuel vapors to escape.',
      whatToDo:
          'Pull over safely and tighten the fuel cap. The light may take several drive cycles to turn off after fixing.',
      beginnerExplanation:
          'Your gas cap is loose! Tighten it until you hear it click. Fuel vapors escaping triggers this warning.',
    ),
    WarningLight(
      id: 'stability_control',
      name: 'Stability Control',
      icon: Icons.track_changes,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: true,
      category: 'Safety',
      whatItMeans:
          'Electronic Stability Control (ESC) has a fault or has been manually disabled. Vehicle is more prone to skidding.',
      whatToDo:
          'Check if you accidentally pressed the ESC button. If the light is solid (not flashing), get it scanned.',
      beginnerExplanation:
          'ESC helps prevent your car from skidding or spinning out in corners. It\'s turned off, so be extra careful when turning quickly.',
    ),
    WarningLight(
      id: 'coolant_level',
      name: 'Coolant Level Low',
      icon: Icons.water_drop,
      color: Color(0xFFFF3B30),
      severity: 'Critical',
      safeToRide: false,
      category: 'Fluid',
      whatItMeans:
          'Engine coolant (antifreeze) level is critically low. Without enough coolant the engine will overheat rapidly.',
      whatToDo:
          'Pull over safely. Do NOT open the radiator cap if the engine is hot. Let it cool for 30+ minutes, then check the coolant reservoir.',
      beginnerExplanation:
          'Coolant keeps your engine from overheating — think of it as the water in a kettle. Without it your engine will boil over and break.',
    ),
    WarningLight(
      id: 'door_ajar',
      name: 'Door Ajar',
      icon: Icons.door_back_door_outlined,
      color: Color(0xFFFFB800),
      severity: 'Info',
      safeToRide: false,
      category: 'Safety',
      whatItMeans: 'One or more doors, the trunk, or the hood is not fully latched.',
      whatToDo: 'Stop safely and check all doors, trunk, and hood are fully closed.',
      beginnerExplanation:
          'A door, the trunk, or the hood isn\'t shut all the way. Stop and close it before driving — it could swing open at speed.',
    ),
    WarningLight(
      id: 'high_beam',
      name: 'High Beams On',
      icon: Icons.highlight,
      color: Color(0xFF40CCFF),
      severity: 'Info',
      safeToRide: true,
      category: 'Electrical',
      whatItMeans: 'High beam headlights are active. Other drivers may be blinded.',
      whatToDo: 'Dim to low beams when there is oncoming traffic or you are following another vehicle.',
      beginnerExplanation:
          'Your bright lights (high beams) are on. They help you see further in the dark but blind other drivers. Dim them when near other cars.',
    ),
    WarningLight(
      id: 'seatbelt',
      name: 'Seatbelt Reminder',
      icon: Icons.airline_seat_recline_normal,
      color: Color(0xFFFF3B30),
      severity: 'Critical',
      safeToRide: false,
      category: 'Safety',
      whatItMeans: 'The driver or a passenger has not fastened their seatbelt.',
      whatToDo: 'Buckle up all occupants immediately. Seatbelts are the single most effective safety device in a vehicle.',
      beginnerExplanation:
          'Someone in the car hasn\'t buckled their seatbelt. Fasten it now — seatbelts save lives in crashes.',
    ),
    WarningLight(
      id: 'dpf',
      name: 'Diesel Particulate Filter',
      icon: Icons.filter_alt_outlined,
      color: Color(0xFFFFB800),
      severity: 'Warning',
      safeToRide: true,
      category: 'Engine',
      whatItMeans:
          'The diesel particulate filter is clogged with soot. A regeneration cycle (burning off the soot) is needed.',
      whatToDo:
          'Drive at motorway speeds for 20–30 minutes to trigger an automatic regeneration cycle. If the light stays on, get it serviced.',
      beginnerExplanation:
          'A filter that cleans your exhaust smoke is blocked. Drive on a fast road (motorway/highway) for a while to let it clean itself.',
    ),
  ];
}
