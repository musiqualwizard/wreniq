import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SoundDiagnosisScreen extends StatefulWidget {
  const SoundDiagnosisScreen({super.key});

  @override
  State<SoundDiagnosisScreen> createState() => _SoundDiagnosisScreenState();
}

class _SoundDiagnosisScreenState extends State<SoundDiagnosisScreen> {
  String? _selectedSound;
  final Set<String> _conditions = {};
  final _descController = TextEditingController();
  _SoundResult? _result;
  bool _analyzing = false;

  static const _sounds = [
    'Squealing', 'Grinding', 'Knocking', 'Ticking',
    'Clicking', 'Hissing', 'Rattling', 'Clunking',
  ];

  static const _conditionOptions = [
    'At startup', 'While driving', 'When braking',
    'When turning', 'At idle', 'While accelerating',
  ];

  static const _db = <String, _SoundResult>{
    'Squealing': _SoundResult(
      likelyCauses: [
        'Worn brake pads contacting the rotor wear indicator (most common)',
        'Slipping or worn serpentine/accessory belt',
        'Dry or seized brake caliper slide pins',
      ],
      urgency: 'High',
      safeToDrive: 'Short distances only — get inspected today',
      costEstimate: '\$100–\$350 (brake pads + labour) or \$75–\$200 (belt)',
      diySearch: 'squealing brakes how to inspect worn brake pads',
    ),
    'Grinding': _SoundResult(
      likelyCauses: [
        'Severely worn brake pads — metal grinding on rotor',
        'Wheel bearing failure (constant grinding that varies with speed)',
        'Debris or stone caught in the brake assembly',
      ],
      urgency: 'CRITICAL',
      safeToDrive: 'NO — brake failure risk is imminent. Stop driving.',
      costEstimate: '\$200–\$500 (brakes and rotors) or \$200–\$500 (wheel bearing)',
      diySearch: 'grinding noise car brakes wheel bearing diagnosis repair',
    ),
    'Knocking': _SoundResult(
      likelyCauses: [
        'Engine knock (detonation) — low octane fuel or carbon buildup',
        'Worn connecting rod bearing — serious internal engine damage',
        'Low oil pressure — check oil level immediately',
      ],
      urgency: 'CRITICAL',
      safeToDrive: 'NO — check oil level immediately. Stop driving if low.',
      costEstimate: '\$500–\$4,000+ depending on severity and repair needed',
      diySearch: 'engine knocking noise diagnosis causes fix rod bearing',
    ),
    'Ticking': _SoundResult(
      likelyCauses: [
        'Low engine oil level (most common — check first)',
        'Worn valve train components: lifters, rocker arms, or cam followers',
        'Exhaust manifold leak (ticking that gets louder when cold)',
      ],
      urgency: 'High',
      safeToDrive: 'Check oil level first. If OK, limit driving until inspected.',
      costEstimate: '\$50 (oil top-up) to \$1,500+ (valve train repair)',
      diySearch: 'engine ticking noise low oil level valve train fix',
    ),
    'Clicking': _SoundResult(
      likelyCauses: [
        'Worn CV joint — clicking primarily when turning (front-wheel drive)',
        'Loose wheel cover, hubcap, or lug nut',
        'Failing starter solenoid (rapid clicking when starting)',
        'Low oil level at startup (single tick)',
      ],
      urgency: 'Medium',
      safeToDrive: 'OK for short local distances — avoid sharp full-lock turns',
      costEstimate: '\$200–\$500 (CV axle replacement) or \$5–\$30 (hubcap)',
      diySearch: 'clicking noise when turning CV joint diagnosis fix',
    ),
    'Hissing': _SoundResult(
      likelyCauses: [
        'Vacuum hose leak — often under the hood near the intake manifold',
        'Coolant leak from a hose, radiator, or water pump',
        'AC refrigerant leak (hissing from engine bay or dashboard)',
        'Power steering fluid leak',
      ],
      urgency: 'Medium-High',
      safeToDrive: 'Monitor temperature gauge closely — stop immediately if overheating',
      costEstimate: '\$30–\$400 depending on source and component',
      diySearch: 'hissing sound under hood vacuum leak coolant leak diagnosis',
    ),
    'Rattling': _SoundResult(
      likelyCauses: [
        'Loose or broken heat shield on exhaust pipe (very common)',
        'Loose exhaust pipe, catalytic converter, or muffler',
        'Worn sway bar end links or bushings',
        'Low transmission or differential fluid',
      ],
      urgency: 'Low-Medium',
      safeToDrive: 'Yes — but get inspected within a week',
      costEstimate: '\$30–\$300 depending on which component is loose',
      diySearch: 'rattling noise under car heat shield exhaust loose fix',
    ),
    'Clunking': _SoundResult(
      likelyCauses: [
        'Worn ball joint or tie rod end (clunk over bumps and turns)',
        'Broken or worn sway bar link',
        'Loose or worn shock absorber/strut mount',
        'Worn engine or transmission mount',
      ],
      urgency: 'High',
      safeToDrive: 'Limit to slow local driving only — suspension failure risk',
      costEstimate: '\$100–\$600 depending on which component needs replacement',
      diySearch: 'clunking noise suspension ball joint sway bar link repair',
    ),
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _diagnose() {
    if (_selectedSound == null) return;
    setState(() => _analyzing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _result = _db[_selectedSound!];
        _analyzing = false;
      });
    });
  }

  Future<void> _openYoutube(String query) async {
    final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOUND DIAGNOSIS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('WHAT SOUND ARE YOU HEARING?'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sounds.map((s) {
                final selected = _selectedSound == s;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedSound = s;
                    _result = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.electricBlue.withValues(alpha: 0.15)
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.electricBlue
                            : AppTheme.chromeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            color: selected
                                ? AppTheme.electricBlue
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('WHEN DOES IT OCCUR? (select all that apply)'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conditionOptions.map((c) {
                final selected = _conditions.contains(c);
                const purple = Color(0xFF9C6FFF);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _conditions.remove(c);
                    } else {
                      _conditions.add(c);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? purple.withValues(alpha: 0.15)
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? purple
                            : AppTheme.chromeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(c,
                        style: TextStyle(
                            color: selected ? purple : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('ADDITIONAL DETAILS (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Describe the sound in more detail — frequency, pitch, gets worse over time, etc.',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_selectedSound == null || _analyzing) ? null : _diagnose,
                icon: _analyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.hearing, size: 18),
                label: Text(_analyzing ? 'Analyzing...' : 'Diagnose Sound'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResult(_result!),
            ],
            const SizedBox(height: 16),
            _disclaimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(_SoundResult r) {
    final isCritical = r.urgency.contains('CRITICAL');
    final isHigh = r.urgency == 'High';
    final urgencyColor = isCritical
        ? const Color(0xFFFF3B30)
        : isHigh
            ? AppTheme.warning
            : const Color(0xFFFF9500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: urgencyColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                  (isCritical || isHigh)
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: urgencyColor,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Urgency: ${r.urgency}',
                        style: TextStyle(
                            color: urgencyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Safe to drive: ${r.safeToDrive}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('LIKELY CAUSES'),
        const SizedBox(height: 8),
        ...r.likelyCauses.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right,
                      color: AppTheme.electricBlue, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(c,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
        _sectionLabel('COST ESTIMATE'),
        const SizedBox(height: 6),
        Text(r.costEstimate,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _openYoutube(r.diySearch),
          icon: const Icon(Icons.play_circle_outline, size: 18),
          label: const Text('Watch DIY Repair Videos'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF6B35),
            side: const BorderSide(color: Color(0xFFFF6B35)),
          ),
        ),
      ],
    );
  }

  Widget _disclaimerCard() {
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
        'Seek professionals for dangerous or safety-critical repairs.',
        style: TextStyle(
            color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.chromeAccent,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600)),
      );
}

class _SoundResult {
  final List<String> likelyCauses;
  final String urgency;
  final String safeToDrive;
  final String costEstimate;
  final String diySearch;

  const _SoundResult({
    required this.likelyCauses,
    required this.urgency,
    required this.safeToDrive,
    required this.costEstimate,
    required this.diySearch,
  });
}
