import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sound_diagnosis.dart';
import '../services/sound_analysis_service.dart';
import '../theme/app_theme.dart';

class SoundDiagnosisScreen extends StatefulWidget {
  const SoundDiagnosisScreen({super.key});

  @override
  State<SoundDiagnosisScreen> createState() => _SoundDiagnosisScreenState();
}

class _SoundDiagnosisScreenState extends State<SoundDiagnosisScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedSound;
  final Set<String> _conditions = {};
  final _descController = TextEditingController();
  SoundDiagnosis? _result;
  bool _analyzing = false;

  // Recording simulation state
  _RecordState _recordState = _RecordState.idle;
  int _recordSeconds = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Recording simulation ──────────────────────────────────────────────────

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _recordState   = _RecordState.recording;
      _recordSeconds = 0;
    });
    _pulseCtrl.repeat(reverse: true);

    // Tick up every second for 3 seconds, then auto-stop
    for (var i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _recordState != _RecordState.recording) return;
      setState(() => _recordSeconds = i);
    }
    await _stopRecording();
  }

  Future<void> _stopRecording() async {
    if (_recordState != _RecordState.recording) return;
    _pulseCtrl.stop();
    setState(() => _recordState = _RecordState.processing);
    HapticFeedback.lightImpact();

    // Simulate brief processing delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() => _recordState = _RecordState.done);
  }

  void _resetRecording() {
    _pulseCtrl.reset();
    setState(() {
      _recordState   = _RecordState.idle;
      _recordSeconds = 0;
    });
  }

  // ── Diagnosis ─────────────────────────────────────────────────────────────

  void _diagnose() {
    if (_selectedSound == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _analyzing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _result = SoundAnalysisService.diagnose(
          soundType:  _selectedSound!,
          conditions: _conditions.toList(),
        );
        _analyzing = false;
      });
      if (_result != null) HapticFeedback.heavyImpact();
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
            _buildRecordSection(),
            const SizedBox(height: 24),
            _sectionLabel('WHAT SOUND ARE YOU HEARING?'),
            const SizedBox(height: 10),
            _buildSoundChips(),
            const SizedBox(height: 20),
            _sectionLabel('WHEN DOES IT OCCUR? (select all that apply)'),
            const SizedBox(height: 10),
            _buildConditionChips(),
            const SizedBox(height: 20),
            _sectionLabel('ADDITIONAL DETAILS (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Describe the sound — pitch, frequency, when it started, gets worse over time…',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedSound == null || _analyzing) ? null : _diagnose,
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

  // ── Record section ────────────────────────────────────────────────────────

  Widget _buildRecordSection() {
    return switch (_recordState) {
      _RecordState.idle       => _recordIdleCard(),
      _RecordState.recording  => _recordActiveCard(),
      _RecordState.processing => _recordProcessingCard(),
      _RecordState.done       => _recordDoneCard(),
    };
  }

  Widget _recordIdleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              border: Border.all(
                  color: AppTheme.electricBlue.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.mic_none_rounded,
                color: AppTheme.electricBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Record the Sound',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 3),
                const Text('Tap to record your car\'s noise',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _startRecording,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  Widget _recordActiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: _pulse.value,
                  child: child,
                ),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF3B30),
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recording...',
                        style: TextStyle(
                            color: Color(0xFFFF3B30),
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      '${_recordSeconds}s — tap Stop when done',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _stopRecording,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF3B30),
                  side: const BorderSide(color: Color(0xFFFF3B30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Waveform decoration
          _MockWaveform(active: true),
        ],
      ),
    );
  }

  Widget _recordProcessingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: AppTheme.electricBlue, strokeWidth: 2.5),
          ),
          SizedBox(width: 14),
          Text('Processing recording...',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _recordDoneCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.success, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Recording captured. Auto-identification coming soon — '
              'please select the sound type below to get an instant diagnosis.',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: _resetRecording,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.refresh,
                  color: AppTheme.chromeAccent, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sound chips ───────────────────────────────────────────────────────────

  Widget _buildSoundChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SoundAnalysisService.soundTypes.map((s) {
        final selected = _selectedSound == s;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedSound = s;
              _result        = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            child: Text(
              s,
              style: TextStyle(
                color: selected
                    ? AppTheme.electricBlue
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Condition chips ───────────────────────────────────────────────────────

  static const _conditionOptions = [
    'At startup', 'While driving', 'When braking',
    'When turning', 'At idle', 'While accelerating',
  ];

  Widget _buildConditionChips() {
    const purple = Color(0xFF9C6FFF);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _conditionOptions.map((c) {
        final selected = _conditions.contains(c);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (selected) {
                _conditions.remove(c);
              } else {
                _conditions.add(c);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            child: Text(
              c,
              style: TextStyle(
                color: selected ? purple : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult(SoundDiagnosis r) {
    final urgencyColor = r.isCritical
        ? const Color(0xFFFF3B30)
        : r.isHigh
            ? AppTheme.warning
            : const Color(0xFFFF9500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urgency card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: urgencyColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                (r.isCritical || r.isHigh)
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: urgencyColor,
                size: 20,
              ),
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
                    const SizedBox(height: 3),
                    Text('Safe to drive: ${r.safeToDrive}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Likely causes
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

        // Recommended actions
        if (r.recommendedActions.isNotEmpty) ...[
          _sectionLabel('RECOMMENDED ACTIONS'),
          const SizedBox(height: 8),
          ...r.recommendedActions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            AppTheme.success.withValues(alpha: 0.15),
                        border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Cost + DIY tag
        _sectionLabel('COST ESTIMATE'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(r.costEstimate,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            if (r.diyPossible)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('DIY Possible',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () => _openYoutube(r.diySearchQuery),
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
        border:
            Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.2)),
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

// ── Recording state ───────────────────────────────────────────────────────────

enum _RecordState { idle, recording, processing, done }

// ── Mock waveform ─────────────────────────────────────────────────────────────

class _MockWaveform extends StatelessWidget {
  final bool active;
  const _MockWaveform({required this.active});

  static const _heights = [6.0, 12.0, 8.0, 16.0, 10.0, 20.0, 8.0, 14.0,
                            6.0, 18.0, 10.0, 14.0, 8.0, 20.0, 12.0, 6.0,
                            16.0, 10.0, 8.0, 14.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights.map((h) => Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF3B30).withValues(alpha: 0.7)
                    : AppTheme.chromeAccent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )).toList(),
      ),
    );
  }
}
