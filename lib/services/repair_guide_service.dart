// ─────────────────────────────────────────────────────────────────────────────
// RepairGuideData — supplemental guide content not yet in ScanResult.
//
// estimatedTime, commonMistakes, whenToCallMechanic are generated from
// repairDifficulty because the AI scan prompt does not request them yet.
// fallbackTools / fallbackSteps are used only when ScanResult fields are empty
// (e.g., very old saved scans from Phase 1).
// ─────────────────────────────────────────────────────────────────────────────

enum DiyConfidenceLevel { beginner, moderate, advanced, professional }

class RepairGuideData {
  final String estimatedTime;
  final List<String> commonMistakes;
  final List<String> whenToCallMechanic;
  final List<String> fallbackTools;
  final List<String> fallbackSteps;

  // ── DIY Companion expansion fields ────────────────────────────────────────
  final DiyConfidenceLevel confidenceLevel;
  final String confidenceLabel;        // e.g. "Safe for beginners"
  final String? torqueWarning;         // null when not applicable
  final String? professionalNotice;    // null when not applicable
  final List<String> safetyFlags;      // ['airbag','ev','fuel','suspension','brake']

  const RepairGuideData({
    required this.estimatedTime,
    required this.commonMistakes,
    required this.whenToCallMechanic,
    required this.fallbackTools,
    required this.fallbackSteps,
    required this.confidenceLevel,
    required this.confidenceLabel,
    this.torqueWarning,
    this.professionalNotice,
    this.safetyFlags = const [],
  });
}

class RepairGuideService {
  static RepairGuideData getGuideData({
    required String partName,
    required String repairDifficulty,
  }) {
    final flags = _detectSafetyFlags(partName);
    final (level, label) = _confidence(repairDifficulty, flags);

    return RepairGuideData(
      estimatedTime:      _time(repairDifficulty),
      commonMistakes:     _mistakes(repairDifficulty),
      whenToCallMechanic: _mechanic(repairDifficulty),
      fallbackTools:      _fallbackTools,
      fallbackSteps:      _fallbackSteps,
      confidenceLevel:    level,
      confidenceLabel:    label,
      torqueWarning:      _torqueWarning(partName),
      professionalNotice: _professionalNotice(repairDifficulty, flags),
      safetyFlags:        flags,
    );
  }

  // ── Safety flag detection ─────────────────────────────────────────────────

  static List<String> _detectSafetyFlags(String partName) {
    final l = partName.toLowerCase();
    return [
      if (l.contains('airbag') || l.contains('srs') ||
          l.contains('air bag') || l.contains('inflator'))
        'airbag',
      if ((l.contains('battery') || l.contains('bms') || l.contains('pack')) &&
          (l.contains('hybrid') || l.contains('ev') ||
           l.contains('electric') || l.contains('high voltage')))
        'ev',
      if (l.contains('fuel') || l.contains('injector') ||
          l.contains('fuel pump') || l.contains('fuel tank'))
        'fuel',
      if (l.contains('suspension') || l.contains('strut') ||
          l.contains('spring') || l.contains('control arm') ||
          l.contains('tie rod') || l.contains('ball joint'))
        'suspension',
      if (l.contains('brake') || l.contains('rotor') ||
          l.contains('caliper') || l.contains('master cylinder'))
        'brake',
    ];
  }

  // ── DIY confidence level ──────────────────────────────────────────────────

  static (DiyConfidenceLevel, String) _confidence(
      String difficulty, List<String> flags) {
    if (flags.contains('airbag') || flags.contains('ev')) {
      return (DiyConfidenceLevel.professional,
          'Professional repair strongly recommended');
    }
    return switch (difficulty.toLowerCase()) {
      'beginner' => (DiyConfidenceLevel.beginner,
          'Safe for confident beginners'),
      'advanced' => flags.isNotEmpty
          ? (DiyConfidenceLevel.professional,
              'Professional repair recommended')
          : (DiyConfidenceLevel.advanced, 'Experienced DIY required'),
      _ => (flags.contains('brake') || flags.contains('suspension'))
          ? (DiyConfidenceLevel.advanced,
              'Experienced DIY — safety-critical system')
          : (DiyConfidenceLevel.moderate, 'Moderate DIY difficulty'),
    };
  }

  // ── Torque warnings ───────────────────────────────────────────────────────

  static String? _torqueWarning(String partName) {
    final l = partName.toLowerCase();
    if (l.contains('brake') || l.contains('caliper') || l.contains('rotor')) {
      return 'Brake caliper bracket bolts: 35–80 Nm (vehicle-specific). '
          'Wheel lug nuts: 80–130 Nm. Always torque to the manufacturer specification '
          'with a calibrated torque wrench — never an impact gun.';
    }
    if (l.contains('spark plug')) {
      return 'Spark plugs: 15–25 Nm on aluminium heads; 20–30 Nm on cast iron. '
          'Do NOT overtighten — stripped aluminium threads are expensive to repair. '
          'Use anti-seize compound on steel plugs into aluminium heads.';
    }
    if (l.contains('oil') || l.contains('drain plug') || l.contains('sump')) {
      return 'Oil drain plug: 20–30 Nm on most vehicles. '
          'Do NOT overtighten on aluminium oil pans — threads strip easily. '
          'Oil filter: hand-tighten firmly then add ¾ turn. Do not use a wrench to tighten.';
    }
    if (l.contains('suspension') || l.contains('strut') ||
        l.contains('control arm') || l.contains('ball joint')) {
      return 'Suspension fasteners MUST be torqued with the vehicle at ride height '
          '(wheels on ground or simulated ride height), not while hanging. '
          'Torquing with the suspension drooped causes premature bushing wear. '
          'Consult the factory service manual torque chart.';
    }
    if (l.contains('wheel') || l.contains('hub') || l.contains('bearing')) {
      return 'Wheel lug nuts/bolts: 80–130 Nm (vehicle-specific) — use a torque wrench, '
          'not an impact gun, for final tightening. '
          'Hub/axle nut: 150–300 Nm — always install a new nut and cotter pin. '
          'Never reuse a prevailing-torque nut.';
    }
    if (l.contains('cylinder head') || l.contains('head bolt') ||
        l.contains('head gasket')) {
      return 'Head bolts require a multi-stage torque sequence (typically 3–4 stages) '
          'specified in the factory service manual. Many head bolts are TTY '
          '(torque-to-yield / stretch bolts) and MUST be replaced, not reused. '
          'Incorrect torque or sequence causes head gasket failure.';
    }
    if (l.contains('timing') || l.contains('cam bolt')) {
      return 'Timing components require precise torque AND a specific tightening sequence. '
          'Cam position and crankshaft must be locked before any disassembly. '
          'Do NOT rotate the engine after timing components are loosened. '
          'Consult the factory service manual — errors cause catastrophic engine damage.';
    }
    return null;
  }

  // ── Professional notice ───────────────────────────────────────────────────

  static String? _professionalNotice(
      String difficulty, List<String> flags) {
    if (flags.contains('airbag')) {
      return 'AIRBAG / SRS SYSTEM — Airbag components carry stored energy '
          'that can deploy unexpectedly, causing serious injury or death. '
          'Disable the SRS system and wait 10+ minutes before any work near airbag modules. '
          'Professional repair is strongly recommended.';
    }
    if (flags.contains('ev')) {
      return 'HIGH-VOLTAGE EV / HYBRID SYSTEM — High-voltage battery packs carry '
          '300–800 V DC, which is lethal. This work must be performed only by '
          'technicians with HV certification, insulated Class 0 gloves, and '
          'appropriate lockout/tagout procedures.';
    }
    if (difficulty.toLowerCase() == 'advanced') {
      return 'ADVANCED REPAIR — If you are not fully confident with any step, '
          'stop and consult a qualified mechanic. Errors can result in costly '
          'engine or drivetrain damage, or create safety hazards.';
    }
    return null;
  }

  // ── Time estimate by difficulty ───────────────────────────────────────────

  static String _time(String difficulty) =>
      switch (difficulty.toLowerCase()) {
        'beginner' => '30 – 60 minutes',
        'advanced' => '3 – 6+ hours',
        _          => '1 – 3 hours',
      };

  // ── Common mistakes by difficulty ─────────────────────────────────────────

  static List<String> _mistakes(String difficulty) {
    final base = [
      'Not consulting the vehicle repair manual before starting.',
      'Over-tightening bolts and stripping threads — always torque to specification.',
      'Losing track of hardware: group fasteners and label connectors before removal.',
      'Skipping a thorough test drive and leak/noise check after installation.',
    ];

    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return [
          ...base,
          'Forgetting to disconnect the negative battery terminal near electrical components.',
          'Rushing reassembly — double-check every connection before closing up.',
        ];
      case 'advanced':
        return [
          'Not following the factory torque sequence — some fasteners must be tightened in a precise order.',
          'Reusing single-use components: seals, gaskets, stretch bolts, and crush washers must always be replaced.',
          'Skipping break-in or re-learn procedures required for the new part.',
          'Mixing incompatible fluids — always verify the correct spec for your vehicle.',
          ...base,
          'Failing to reset adaptive systems after replacement (throttle body, TPMS, brake wear sensor, etc.).',
        ];
      default: // intermediate
        return [
          'Reusing single-use fasteners such as stretch bolts or crush washers.',
          'Not bleeding fluid systems after opening hydraulic lines.',
          'Installing components in the wrong orientation — photograph before disassembly.',
          'Skipping the cleaning of mating surfaces before fitting new parts.',
          'Not inspecting for hidden damage while the area is already disassembled.',
          ...base,
        ];
    }
  }

  // ── When to stop and call a professional ─────────────────────────────────

  static List<String> _mechanic(String difficulty) => [
        'You are uncertain or uncomfortable with any step — stop and ask a professional.',
        'Fasteners are seized, corroded, rounded, or stripped beyond safe removal.',
        'You discover unexpected additional damage during disassembly.',
        'The repair involves the fuel system, airbag (SRS), ABS, or high-voltage hybrid/EV components.',
        'Specialised tools are required that are not practical to rent or borrow.',
        if (difficulty.toLowerCase() == 'advanced')
          'Precision measurements or factory-level diagnostic equipment are required.',
        'The vehicle is used commercially or for safety-critical or emergency purposes.',
      ];

  // ── Fallback tools (when ScanResult.toolsNeeded is empty) ─────────────────

  static const List<String> _fallbackTools = [
    'Socket set — metric and standard (3/8" and 1/2" drive)',
    'Combination wrench set',
    'Torque wrench (rated for the required spec)',
    'Flathead and Phillips screwdriver set',
    'Pliers and needle-nose pliers',
    'Floor jack and rated jack stands',
    'Safety glasses and nitrile work gloves',
  ];

  // ── Fallback steps (when ScanResult.repairSteps is empty) ─────────────────

  static const List<String> _fallbackSteps = [
    'Gather all required tools, parts, and safety equipment before starting.',
    'Park on a level, solid surface and engage the parking brake firmly.',
    'Allow the vehicle to cool fully — do not work near hot exhaust or engine components.',
    'Disconnect the negative battery terminal if working near electrical components.',
    'Raise the vehicle safely with a floor jack and secure it on rated jack stands if needed.',
    'Remove any panels, covers, or obstructing components to gain clear access.',
    'Photograph the area before disassembly — note wire routing, hose positions, and bolt locations.',
    'Remove the old part carefully, keeping track of every fastener and connector.',
    'Inspect the surrounding area for additional wear or damage while access is open.',
    'Clean all mating surfaces, threaded holes, and contact areas before installing.',
    'Install the new part in the reverse order of removal; torque all fasteners to specification.',
    'Reinstall all panels and components that were removed for access.',
    'Reconnect the battery if it was disconnected.',
    'Start the vehicle and check for leaks, warning lights, or abnormal noises.',
    'Take a careful low-speed test drive to verify the repair before returning to normal use.',
  ];
}
