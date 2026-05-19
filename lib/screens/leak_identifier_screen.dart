import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/fluid_leak.dart';
import '../services/beginner_mode_service.dart';
import '../services/leak_service.dart';
import '../theme/app_theme.dart';

class LeakIdentifierScreen extends StatefulWidget {
  const LeakIdentifierScreen({super.key});

  @override
  State<LeakIdentifierScreen> createState() => _LeakIdentifierScreenState();
}

class _LeakIdentifierScreenState extends State<LeakIdentifierScreen> {
  int    _step = 0;
  String? _colorCategory;
  List<FluidLeak>? _results;

  static const _colors = <_ColorOption>[
    _ColorOption(id: 'black_brown', label: 'Dark Brown / Black',       color: Color(0xFF3D2400), description: 'Very dark, like old motor oil'),
    _ColorOption(id: 'red_pink',    label: 'Red / Pink',               color: Color(0xFFE53935), description: 'Bright red or reddish pink'),
    _ColorOption(id: 'green_yellow',label: 'Green / Yellow / Orange',  color: Color(0xFF00C853), description: 'Bright colour, sweet smell'),
    _ColorOption(id: 'clear',       label: 'Clear / Colourless',       color: Color(0xFFB0BEC5), description: 'Water-like, possibly with slight yellow tint'),
    _ColorOption(id: 'orange',      label: 'Orange / Rusty',           color: Color(0xFFFF6D00), description: 'Orange or rust-coloured'),
  ];

  static const _locations = <_LocOption>[
    _LocOption(id: 'front',   label: 'Under the Front',   icon: Icons.arrow_upward,   description: 'Near the radiator, engine front'),
    _LocOption(id: 'center',  label: 'Under the Middle',  icon: Icons.drag_handle,    description: 'Under the engine, centre of car'),
    _LocOption(id: 'rear',    label: 'Under the Back',    icon: Icons.arrow_downward, description: 'Near the exhaust or rear wheels'),
    _LocOption(id: 'unknown', label: 'Not Sure',          icon: Icons.help_outline,   description: 'Not certain where exactly'),
  ];

  void _pickColor(_ColorOption opt) {
    HapticFeedback.lightImpact();
    setState(() { _colorCategory = opt.id; _step = 1; });
  }

  void _pickLocation(_LocOption opt) {
    HapticFeedback.lightImpact();
    final results = LeakService.identify(
      colorCategory: _colorCategory!,
      location:      opt.id,
    );
    setState(() { _results = results; _step = 2; });
  }

  void _reset() => setState(() { _step = 0; _colorCategory = null; _results = null; });

  @override
  Widget build(BuildContext context) {
    final beginner = context.watch<BeginnerModeService>().enabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LEAK IDENTIFIER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: _step > 0 ? () => setState(() => _step--) : () => Navigator.pop(context),
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8), child: _BeginnerToggle()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 20),
            if (_step == 0) _buildStep0(beginner),
            if (_step == 1) _buildStep1(beginner),
            if (_step == 2) _buildResults(beginner),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(3, (i) {
        final done = i <= _step;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: done ? AppTheme.electricBlue : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep0(bool beginner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          beginner ? 'Step 1 of 2 — What colour is the puddle?' : 'Step 1 — Fluid Colour',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          beginner
              ? 'Look at the puddle under your car. What colour does it look like?'
              : 'Select the closest colour match to the leaked fluid.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ..._colors.map((opt) => GestureDetector(
          onTap: () => _pickColor(opt),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: opt.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: opt.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: opt.color.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(opt.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.chromeAccent, size: 18),
              ],
            ),
          ),
        )),
        const SizedBox(height: 16),
        _SafetyNote(),
      ],
    );
  }

  Widget _buildStep1(bool beginner) {
    final selectedColor = _colors.firstWhere((c) => c.id == _colorCategory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: selectedColor.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(selectedColor.label, style: const TextStyle(color: AppTheme.chromeAccent, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Text(
          beginner ? 'Step 2 of 2 — Where is the leak?' : 'Step 2 — Leak Location',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          beginner
              ? 'Roughly where under the car is the puddle?'
              : 'Select the location of the fluid accumulation.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ..._locations.map((opt) => GestureDetector(
          onTap: () => _pickLocation(opt),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.electricBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(opt.icon, color: AppTheme.electricBlue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(opt.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.chromeAccent, size: 18),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildResults(bool beginner) {
    final results = _results!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          beginner ? 'Possible Fluid Match' : 'Identification Results',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          results.isEmpty
              ? 'No common fluid matched your selection.'
              : '${results.length} possible match${results.length == 1 ? '' : 'es'} found',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (results.isEmpty)
          _NoMatch(onReset: _reset)
        else ...[
          ...results.map((l) => _LeakCard(leak: l, beginner: beginner)),
          const SizedBox(height: 16),
          _SafetyNote(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Start Over'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.chromeAccent,
                side: BorderSide(color: AppTheme.chromeAccent.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LeakCard extends StatefulWidget {
  final FluidLeak leak;
  final bool      beginner;
  const _LeakCard({required this.leak, required this.beginner});

  @override
  State<_LeakCard> createState() => _LeakCardState();
}

class _LeakCardState extends State<_LeakCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l        = widget.leak;
    final beginner = widget.beginner;
    final severity = l.severity;
    final sColor   = severity == 'Critical'
        ? const Color(0xFFFF3B30)
        : severity == 'High'
            ? const Color(0xFFFF6B35)
            : severity == 'Medium'
                ? const Color(0xFFFFB800)
                : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: l.typicalColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.fluidType, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(l.colorDescription, style: const TextStyle(color: AppTheme.chromeAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(severity, style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.chromeAccent, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFF2A2A3E)),
                  const SizedBox(height: 12),
                  // Drive-ability
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (l.driveableNow ? AppTheme.success : const Color(0xFFFF3B30)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (l.driveableNow ? AppTheme.success : const Color(0xFFFF3B30)).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          l.driveableNow ? Icons.check_circle : Icons.dangerous,
                          color: l.driveableNow ? AppTheme.success : const Color(0xFFFF3B30),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.driveableNow ? 'Can drive — but repair soon' : 'Do NOT drive — risk of serious damage',
                          style: TextStyle(
                            color: l.driveableNow ? AppTheme.success : const Color(0xFFFF3B30),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Beginner or tech explanation
                  _DetailRow(label: 'EXPLANATION',
                    value: beginner ? l.beginnerExplanation : 'Texture: ${l.texture}  •  Smell: ${l.smell}'),
                  const SizedBox(height: 10),
                  // What to do
                  _DetailRow(label: beginner ? 'WHAT TO DO' : 'RECOMMENDED ACTION', value: l.whatToDo),
                  const SizedBox(height: 10),
                  // Common causes
                  const Text('COMMON CAUSES',
                    style: TextStyle(color: AppTheme.electricBlue, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...l.commonCauses.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.fiber_manual_record, size: 8, color: AppTheme.electricBlue.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    ]),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.electricBlue, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
      ],
    );
  }
}

class _NoMatch extends StatelessWidget {
  final VoidCallback onReset;
  const _NoMatch({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Icon(Icons.search_off, color: AppTheme.chromeAccent, size: 40),
              SizedBox(height: 12),
              Text('No match found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Your selection didn\'t match common fluid types. Try different options or consult a mechanic.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}

class _SafetyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.shield_outlined, color: Color(0xFFFFB800), size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI and visual identification may be incorrect. Brake fluid leaks are always emergencies — do not drive. Always verify with a qualified mechanic.',
            style: TextStyle(color: Color(0xFFFFB800), fontSize: 11, height: 1.4),
          ),
        ),
      ]),
    );
  }
}

class _BeginnerToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BeginnerModeService>();
    return GestureDetector(
      onTap: svc.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: svc.enabled ? AppTheme.electricBlue.withValues(alpha: 0.15) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: svc.enabled ? AppTheme.electricBlue.withValues(alpha: 0.6) : AppTheme.chromeAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school_outlined, size: 14, color: svc.enabled ? AppTheme.electricBlue : AppTheme.chromeAccent),
          const SizedBox(width: 4),
          Text('Beginner', style: TextStyle(fontSize: 11, color: svc.enabled ? AppTheme.electricBlue : AppTheme.chromeAccent)),
        ]),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _ColorOption {
  final String id;
  final String label;
  final Color  color;
  final String description;
  const _ColorOption({required this.id, required this.label, required this.color, required this.description});
}

class _LocOption {
  final String   id;
  final String   label;
  final IconData icon;
  final String   description;
  const _LocOption({required this.id, required this.label, required this.icon, required this.description});
}
