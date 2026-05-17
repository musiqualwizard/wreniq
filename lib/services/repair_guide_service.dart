// ─────────────────────────────────────────────────────────────────────────────
// RepairGuideData — supplemental guide content not yet in ScanResult.
//
// estimatedTime, commonMistakes, whenToCallMechanic are generated from
// repairDifficulty because the AI scan prompt does not request them yet.
// fallbackTools / fallbackSteps are used only when ScanResult fields are empty
// (e.g., very old saved scans from Phase 1).
// ─────────────────────────────────────────────────────────────────────────────
class RepairGuideData {
  final String estimatedTime;
  final List<String> commonMistakes;
  final List<String> whenToCallMechanic;
  final List<String> fallbackTools;
  final List<String> fallbackSteps;

  const RepairGuideData({
    required this.estimatedTime,
    required this.commonMistakes,
    required this.whenToCallMechanic,
    required this.fallbackTools,
    required this.fallbackSteps,
  });
}

class RepairGuideService {
  static RepairGuideData getGuideData({
    required String partName,
    required String repairDifficulty,
  }) {
    return RepairGuideData(
      estimatedTime:      _time(repairDifficulty),
      commonMistakes:     _mistakes(repairDifficulty),
      whenToCallMechanic: _mechanic(repairDifficulty),
      fallbackTools:      _fallbackTools,
      fallbackSteps:      _fallbackSteps,
    );
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
    'Specialized tools are required that are not practical to rent or borrow.',
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

  // ── Fallback steps (when ScanResult.repairSteps is empty) ────────────────
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
