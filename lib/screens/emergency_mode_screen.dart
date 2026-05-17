import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmergencyModeScreen extends StatefulWidget {
  const EmergencyModeScreen({super.key});

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen> {
  int? _selected;

  static const _emergencies = [
    _Emergency(
      icon: Icons.no_crash,
      label: "Car Won't Start",
      color: Color(0xFFFF9500),
      safeLabel: 'Not applicable — vehicle is stationary',
      urgency: 'Low — call roadside if needed',
      steps: [
        "Check that the gear selector is in Park (automatic) or Neutral (manual).",
        "Listen when you turn the key: rapid clicking = dead battery; complete silence = starter or electrical issue; cranking but no fire = fuel or ignition problem.",
        "Inspect battery terminals for corrosion (white or blue powder buildup).",
        "Try jump-starting using a good battery and proper jumper cables.",
        "If the vehicle starts after a jump, drive directly to a shop — the battery or alternator likely needs replacing.",
      ],
      notDo: [
        "Do NOT keep cranking the engine repeatedly — you risk flooding it with fuel.",
        "Do NOT ignore a burning smell when attempting to start.",
      ],
    ),
    _Emergency(
      icon: Icons.thermostat,
      label: 'Overheating',
      color: Color(0xFFFF3B30),
      safeLabel: 'STOP IMMEDIATELY',
      urgency: 'CRITICAL',
      steps: [
        "Pull over safely as soon as possible and turn off the engine.",
        "Turn the cabin heater to MAX — this helps draw heat away from the engine block.",
        "Do NOT open the hood for at least 15 minutes — escaping steam can cause severe burns.",
        "Allow the engine to cool for 30+ minutes before touching anything under the hood.",
        "Once cool, check the coolant overflow reservoir level only. Never open the radiator cap when warm.",
        "If coolant is empty or the vehicle cannot be safely driven, call roadside assistance.",
      ],
      notDo: [
        "NEVER open the radiator cap while the engine is hot — pressurised boiling coolant causes severe burns.",
        "Do NOT pour cold water into a hot engine — thermal shock can crack the engine block or head.",
        "Do NOT keep driving — warping the cylinder head costs \$1,500 or more to repair.",
      ],
    ),
    _Emergency(
      icon: Icons.battery_alert,
      label: 'Battery Dead',
      color: Color(0xFFFFD60A),
      safeLabel: 'Limited — vehicle may stall mid-drive',
      urgency: 'Medium',
      steps: [
        "Find a vehicle with a charged battery and a set of jumper cables.",
        "Connect the RED cable to the dead battery positive (+) terminal, then to the good battery positive (+).",
        "Connect the BLACK cable to the good battery negative (–), then to unpainted bare metal on the dead car — not the battery.",
        "Start the donor vehicle and let it run for 2–3 minutes.",
        "Start your vehicle. If it starts, drive for 15–30 minutes to recharge the battery.",
        "Have the battery and alternator tested at a shop — one of them likely needs replacing.",
      ],
      notDo: [
        "NEVER connect jumper cables in the wrong order — reverse polarity can destroy electronics instantly.",
        "Do NOT disconnect the jumper cables while either engine is running.",
        "Do NOT drive if the battery warning light remains on — the alternator may be failing.",
      ],
    ),
    _Emergency(
      icon: Icons.volume_up,
      label: 'Strange Noise',
      color: Color(0xFFFF9500),
      safeLabel: 'Depends on the noise type',
      urgency: 'Medium-High',
      steps: [
        "Note exactly when the noise occurs: at startup, while driving, when braking, when turning, or constantly.",
        "Grinding when braking = severely worn brake pads. Stop driving immediately.",
        "Knocking from the engine = low oil or serious internal damage. Check oil level now.",
        "Squealing belt = serpentine belt slipping. Can cause sudden loss of power steering.",
        "Slow down and avoid highway speeds until the vehicle has been inspected.",
        "Get the vehicle to a mechanic the same day for any grinding or engine knocking sounds.",
      ],
      notDo: [
        "Do NOT ignore grinding sounds — brake or bearing failure can occur without further warning.",
        "Do NOT drive at highway speed with an undiagnosed noise.",
      ],
    ),
    _Emergency(
      icon: Icons.warning_amber_rounded,
      label: 'Warning Light On',
      color: Color(0xFFFF9500),
      safeLabel: 'Depends on the specific light',
      urgency: 'Varies by light colour',
      steps: [
        "RED lights = pull over safely as soon as possible — these indicate an immediate problem.",
        "YELLOW/AMBER lights = get the vehicle inspected within 1–2 days.",
        "FLASHING lights of any colour = pull over immediately and call for assistance.",
        "Oil pressure light (red oil can) = stop immediately and check the oil level.",
        "Temperature gauge in the red = overheating — see the Overheating guide.",
        "Battery light = alternator likely failing — drive directly to a shop today.",
        "Check Engine light (steady amber) = scan for fault codes with an OBD reader.",
      ],
      notDo: [
        "NEVER ignore a red oil pressure or engine temperature warning — engine damage can occur within minutes.",
        "Do NOT assume a warning light will clear itself — get it scanned.",
      ],
    ),
    _Emergency(
      icon: Icons.tire_repair,
      label: 'Flat Tire',
      color: Color(0xFF00B4FF),
      safeLabel: 'Pull over safely NOW',
      urgency: 'High',
      steps: [
        "Grip the steering wheel firmly — do NOT yank or make sudden steering inputs.",
        "Gradually ease off the accelerator — do NOT brake hard.",
        "Steer gently toward the nearest safe shoulder, exit, or parking area.",
        "Activate your hazard lights before stopping completely.",
        "If on a highway, stay behind the guard rail while changing the tire or waiting for help.",
        "Install your spare tire following the vehicle owner's manual instructions.",
        "Call roadside assistance if you do not have a spare or feel unsafe changing on the road.",
      ],
      notDo: [
        "Do NOT brake suddenly — you can lose control of the vehicle.",
        "Do NOT drive on a flat tire — you will destroy the wheel rim (\$300–\$800 to replace).",
        "Do NOT change a tire on an active highway lane — move to an exit or call for assistance.",
      ],
    ),
    _Emergency(
      icon: Icons.speed,
      label: 'Brake Failure',
      color: Color(0xFFFF3B30),
      safeLabel: 'STOP DRIVING IMMEDIATELY',
      urgency: 'CRITICAL',
      steps: [
        "If brakes feel soft or spongy: pump the pedal rapidly and repeatedly to build hydraulic pressure.",
        "Shift to a lower gear immediately — automatic: move selector to L or 2; manual: downshift sequentially.",
        "Apply the parking/emergency brake very gradually and gently — not in one sharp pull.",
        "Steer toward an uphill slope, gravel shoulder, guardrail, or soft obstacle to scrub speed.",
        "Activate hazard lights and sound the horn continuously to warn other road users.",
        "Do NOT turn off the ignition — you will lose power steering and power brakes.",
        "Call emergency services (911) if you cannot bring the vehicle to a safe stop.",
      ],
      notDo: [
        "Do NOT yank the parking brake hard at speed — it can cause an immediate spin or skid.",
        "Do NOT turn off the engine — you lose both power steering and brake boost.",
        "NEVER drive the vehicle again until the brake system has been fully inspected and repaired.",
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('EMERGENCY MODE'),
        backgroundColor: const Color(0xFFCC1A10),
        leading: _selected != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selected = null),
              )
            : null,
      ),
      body: _selected == null
          ? _buildMenu()
          : _buildDetail(_emergencies[_selected!]),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _warningBanner(),
          const SizedBox(height: 20),
          ...List.generate(_emergencies.length, (i) {
            final e = _emergencies[i];
            return GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: e.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: e.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.icon, color: e.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(e.label,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: AppTheme.chromeAccent, size: 14),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          _safetyDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildDetail(_Emergency e) {
    final isCritical = e.urgency.contains('CRITICAL');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: e.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(e.icon, color: e.color, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.label,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: isCritical
                                ? const Color(0xFFFF3B30)
                                : e.color),
                        const SizedBox(width: 6),
                        Text(e.urgency,
                            style: TextStyle(
                                color: isCritical
                                    ? const Color(0xFFFF3B30)
                                    : e.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCritical
                    ? const Color(0xFFFF3B30).withValues(alpha: 0.4)
                    : AppTheme.chromeAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.drive_eta,
                    color: isCritical
                        ? const Color(0xFFFF3B30)
                        : AppTheme.chromeAccent,
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Safe to drive: ${e.safeLabel}',
                      style: TextStyle(
                          color: isCritical
                              ? const Color(0xFFFF3B30)
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('WHAT TO DO'),
          const SizedBox(height: 10),
          ...List.generate(e.steps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: e.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.steps[i],
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _sectionLabel('DO NOT'),
          const SizedBox(height: 10),
          ...e.notDo.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.block,
                        color: Color(0xFFFF3B30), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(n,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          _safetyDisclaimer(),
        ],
      ),
    );
  }

  Widget _warningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_fire_department,
              color: Color(0xFFFF3B30), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'If you are in danger, call 911 immediately. These guides are for informational purposes only. Always prioritise your safety above all else.',
              style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppTheme.chromeAccent.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'AI may be incorrect. Verify repairs and follow proper safety procedures. '
        'Seek professionals for dangerous repairs. Always call 911 in a life-threatening emergency.',
        style: TextStyle(
            color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.chromeAccent,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600));
}

class _Emergency {
  final IconData icon;
  final String label;
  final Color color;
  final String safeLabel;
  final String urgency;
  final List<String> steps;
  final List<String> notDo;

  const _Emergency({
    required this.icon,
    required this.label,
    required this.color,
    required this.safeLabel,
    required this.urgency,
    required this.steps,
    required this.notDo,
  });
}
