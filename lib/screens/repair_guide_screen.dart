import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_result.dart';
import '../services/checklist_service.dart';
import '../services/repair_estimate_service.dart';
import '../services/repair_guide_service.dart';
import '../theme/app_theme.dart';
import 'mechanic_chat_screen.dart';
import 'repair_estimate_screen.dart';

class RepairGuideScreen extends StatefulWidget {
  final ScanResult scan;
  const RepairGuideScreen({super.key, required this.scan});

  @override
  State<RepairGuideScreen> createState() => _RepairGuideScreenState();
}

class _RepairGuideScreenState extends State<RepairGuideScreen> {
  static const Color _teal   = Color(0xFF00D4AA);
  static const Color _purple = Color(0xFF9C6FFF);

  // ── Checklist state ──────────────────────────────────────────────────────
  Set<int> _checkedTools = {};
  Set<int> _checkedSteps = {};
  Set<int> _expandedSteps = {};
  bool _isLoading = true;

  // ── UI mode state ─────────────────────────────────────────────────────────
  bool _darkMode  = false;
  bool _watchMode = false;
  bool _completionShown = false;

  late final RepairGuideData _guide;
  late final List<String>    _tools;
  late final List<String>    _steps;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _guide = RepairGuideService.getGuideData(
      partName:         widget.scan.partName,
      repairDifficulty: widget.scan.repairDifficulty,
    );
    _tools = widget.scan.toolsNeeded.isNotEmpty
        ? widget.scan.toolsNeeded
        : _guide.fallbackTools;
    _steps = widget.scan.repairSteps.isNotEmpty
        ? widget.scan.repairSteps
        : _guide.fallbackSteps;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final tools = await ChecklistService.loadCheckedTools(widget.scan.id);
    final steps = await ChecklistService.loadCheckedSteps(widget.scan.id);
    if (mounted) {
      setState(() {
        _checkedTools = tools;
        _checkedSteps = steps;
        _isLoading    = false;
      });
    }
  }

  // ── Progress helpers ──────────────────────────────────────────────────────

  int get _totalItems   => _steps.length;
  int get _checkedItems => _checkedSteps.length;
  bool get _allDone     => _totalItems > 0 && _checkedItems == _totalItems;
  int get _ownedTools   => _checkedTools.length;
  int get _missingTools => _tools.length - _ownedTools;

  double get _estimatedSavings {
    final mid = (widget.scan.estimatedPriceLow + widget.scan.estimatedPriceHigh) / 2;
    return mid > 0 ? mid * 0.55 : 80.0;
  }

  // ── Toggle handlers ───────────────────────────────────────────────────────

  Future<void> _toggleTool(int i) async {
    HapticFeedback.lightImpact();
    setState(() =>
        _checkedTools.contains(i) ? _checkedTools.remove(i) : _checkedTools.add(i));
    await ChecklistService.saveCheckedTools(widget.scan.id, _checkedTools);
  }

  Future<void> _toggleStep(int i) async {
    HapticFeedback.lightImpact();
    setState(() =>
        _checkedSteps.contains(i) ? _checkedSteps.remove(i) : _checkedSteps.add(i));
    await ChecklistService.saveCheckedSteps(widget.scan.id, _checkedSteps);
    if (_allDone && !_completionShown) {
      _completionShown = true;
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) _showCompletion();
    }
  }

  void _toggleExpand(int i) =>
      setState(() => _expandedSteps.contains(i)
          ? _expandedSteps.remove(i)
          : _expandedSteps.add(i));

  Future<void> _resetProgress() async {
    await ChecklistService.clearAll(widget.scan.id);
    if (mounted) {
      setState(() {
        _checkedTools    = {};
        _checkedSteps    = {};
        _expandedSteps   = {};
        _completionShown = false;
      });
    }
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CompletionDialog(
        partName: widget.scan.partName,
        savings:  _estimatedSavings,
      ),
    );
  }

  Future<void> _openYoutubeForRepair() async {
    final query =
        '${widget.scan.partName} ${widget.scan.vehicleInfo.split(",").first} repair how to';
    final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────

  Color get _bgColor   => _darkMode ? const Color(0xFF050508) : AppTheme.background;
  Color get _cardColor => _darkMode ? const Color(0xFF0D0D15) : AppTheme.cardColor;
  Color get _surfaceColor => _darkMode ? Colors.black : AppTheme.surface;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.electricBlue)),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        title: _watchMode
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('REPAIR GUIDE'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('WATCH MODE',
                      style: TextStyle(
                          color: _teal, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ])
            : const Text('REPAIR GUIDE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Watch while repairing toggle
          IconButton(
            tooltip: _watchMode ? 'Exit Watch Mode' : 'Watch While Repairing',
            icon: Icon(
              _watchMode ? Icons.videocam : Icons.videocam_outlined,
              color: _watchMode ? _teal : AppTheme.chromeAccent,
            ),
            onPressed: () => setState(() => _watchMode = !_watchMode),
          ),
          // Dark repair mode toggle
          IconButton(
            tooltip: _darkMode ? 'Exit Dark Mode' : 'Dark Repair Mode',
            icon: Icon(
              _darkMode ? Icons.light_mode : Icons.dark_mode_outlined,
              color: _darkMode ? const Color(0xFFFFD60A) : AppTheme.chromeAccent,
            ),
            onPressed: () => setState(() => _darkMode = !_darkMode),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: _watchMode ? _buildWatchView() : _buildNormalView(),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    final progress = _totalItems > 0 ? _checkedItems / _totalItems : 0.0;
    final barColor = _allDone ? AppTheme.success : _teal;
    final label    = _allDone
        ? 'All steps complete!'
        : '$_checkedItems of $_totalItems steps done';

    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROGRESS',
                  style: TextStyle(
                      color: AppTheme.chromeAccent,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: TextStyle(
                      color: barColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.cardColor,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Safety flags banner ───────────────────────────────────────────────────

  Widget? _buildSafetyFlagsBanner() {
    if (_guide.safetyFlags.isEmpty) return null;

    final banners = _guide.safetyFlags.map((flag) {
      final (color, icon, text) = switch (flag) {
        'airbag' => (
            const Color(0xFFFF3B30),
            Icons.warning_rounded,
            'AIRBAG / SRS — Disable the SRS system and wait 10+ minutes before touching airbag components. Risk of accidental deployment.',
          ),
        'ev' => (
            const Color(0xFFFF3B30),
            Icons.bolt,
            'HIGH-VOLTAGE EV / HYBRID — 300–800 V lethal voltage. Certified technicians with HV equipment only.',
          ),
        'fuel' => (
            const Color(0xFFFF9500),
            Icons.local_fire_department_outlined,
            'FUEL SYSTEM — Work in a well-ventilated area. No open flames or sparks. Have a fire extinguisher nearby.',
          ),
        'suspension' => (
            const Color(0xFFFF9500),
            Icons.warning_amber_rounded,
            'SUSPENSION — Never work under a vehicle supported only by a floor jack. Use rated jack stands on firm ground.',
          ),
        'brake' => (
            const Color(0xFFFF9500),
            Icons.report_problem_outlined,
            'BRAKE SYSTEM — Safety-critical repair. Test all braking thoroughly at low speed before driving normally.',
          ),
        _ => (AppTheme.warning, Icons.info_outline, flag),
      };

      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: color.withValues(alpha: 0.1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color, fontSize: 12, height: 1.4)),
            ),
          ],
        ),
      );
    }).toList();

    return Column(children: banners);
  }

  // ── Professional notice banner ─────────────────────────────────────────────

  Widget? _buildProfessionalNotice() {
    final notice = _guide.professionalNotice;
    if (notice == null) return null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.engineering_outlined,
              color: Color(0xFFFF3B30), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(notice,
                style: const TextStyle(
                    color: Color(0xFFFF3B30), fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ── Normal view ───────────────────────────────────────────────────────────

  Widget _buildNormalView() {
    final flagsBanner   = _buildSafetyFlagsBanner();
    final proNotice     = _buildProfessionalNotice();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ?flagsBanner,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (proNotice != null) ...[proNotice, const SizedBox(height: 14)],
              _buildHeader(),
              const SizedBox(height: 14),
              if (widget.scan.safetyWarnings.isNotEmpty) ...[
                _buildSafetyWarnings(),
                const SizedBox(height: 14),
              ],
              _buildToolsChecklist(),
              const SizedBox(height: 14),
              _buildStepsChecklist(),
              const SizedBox(height: 14),
              _buildCommonMistakes(),
              const SizedBox(height: 14),
              _buildWhenToCallMechanic(),
              const SizedBox(height: 20),
              _buildDisclaimer(),
              const SizedBox(height: 14),
              _buildEstimateButton(),
              const SizedBox(height: 8),
              _buildAskButton(),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: (_checkedItems > 0 || _ownedTools > 0)
                      ? _resetProgress
                      : null,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset Progress'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.chromeAccent),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ── Watch mode view ───────────────────────────────────────────────────────

  Widget _buildWatchView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Watch mode notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _teal.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.videocam_outlined, color: _teal, size: 16),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Watch Mode — larger text for hands-free reading. '
                  'Prevent screen sleep in your device Settings → Display.',
                  style: TextStyle(color: _teal, fontSize: 12, height: 1.3),
                ),
              ),
              GestureDetector(
                onTap: _openYoutubeForRepair,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_circle_outline,
                          color: Color(0xFFFF6B6B), size: 14),
                      SizedBox(width: 4),
                      Text('YouTube',
                          style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Safety warnings (keep visible in watch mode)
        if (widget.scan.safetyWarnings.isNotEmpty) ...[
          _buildSafetyWarnings(),
          const SizedBox(height: 14),
        ],

        // Steps — large cards
        Text('STEPS ($_checkedItems/${_steps.length})',
            style: const TextStyle(
                color: AppTheme.chromeAccent,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),

        ..._steps.asMap().entries.map((e) => _watchStepCard(e.key, e.value)),

        const SizedBox(height: 16),
        _buildAskButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _watchStepCard(int index, String step) {
    final done = _checkedSteps.contains(index);

    return GestureDetector(
      onTap: () => _toggleStep(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: done
              ? AppTheme.success.withValues(alpha: 0.08)
              : _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done
                ? AppTheme.success.withValues(alpha: 0.4)
                : AppTheme.chromeAccent.withValues(alpha: 0.15),
            width: done ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: done
                    ? AppTheme.success.withValues(alpha: 0.2)
                    : AppTheme.electricBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: done
                    ? Border.all(color: AppTheme.success, width: 1.5)
                    : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check,
                        color: AppTheme.success, size: 18)
                    : Text('${index + 1}',
                        style: const TextStyle(
                            color: AppTheme.electricBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step,
                    style: TextStyle(
                      color: done
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontSize: 17,
                      height: 1.5,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.textSecondary,
                    ),
                  ),
                  if (!done) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _openAskForStep(index, step),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.smart_toy_outlined,
                              color: _purple, size: 13),
                          SizedBox(width: 5),
                          Text('Ask Wreniq about this step',
                              style: TextStyle(
                                  color: _purple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (part name + badges + confidence + torque) ─────────────────────

  Widget _buildHeader() {
    final diffColor = switch (widget.scan.repairDifficulty.toLowerCase()) {
      'beginner' => AppTheme.success,
      'advanced' => AppTheme.warning,
      _          => AppTheme.electricBlue,
    };
    final confColor = _confidenceColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.build_outlined, 'REPLACEMENT GUIDE', _teal),
          const SizedBox(height: 10),
          Text(
            widget.scan.partName,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(widget.scan.vehicleInfo,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),

          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(
                  icon: Icons.speed_outlined,
                  label: widget.scan.repairDifficulty,
                  color: diffColor),
              _badge(
                  icon: Icons.access_time_outlined,
                  label: _guide.estimatedTime,
                  color: _teal),
            ],
          ),

          const SizedBox(height: 10),

          // DIY Confidence score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: confColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: confColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(_confidenceIcon, color: confColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_guide.confidenceLabel,
                      style: TextStyle(
                          color: confColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Torque warning (if applicable)
          if (_guide.torqueWarning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hardware,
                      color: Color(0xFFFF9500), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TORQUE SPECIFICATION',
                            style: TextStyle(
                                color: Color(0xFFFF9500),
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(_guide.torqueWarning!,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _confidenceColor => switch (_guide.confidenceLevel) {
        DiyConfidenceLevel.beginner     => AppTheme.success,
        DiyConfidenceLevel.moderate     => AppTheme.electricBlue,
        DiyConfidenceLevel.advanced     => const Color(0xFFFF9500),
        DiyConfidenceLevel.professional => AppTheme.warning,
      };

  IconData get _confidenceIcon => switch (_guide.confidenceLevel) {
        DiyConfidenceLevel.beginner     => Icons.check_circle_outline,
        DiyConfidenceLevel.moderate     => Icons.build_circle_outlined,
        DiyConfidenceLevel.advanced     => Icons.warning_amber_rounded,
        DiyConfidenceLevel.professional => Icons.engineering,
      };

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Safety warnings ───────────────────────────────────────────────────────

  Widget _buildSafetyWarnings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
              Icons.warning_amber_rounded, 'SAFETY FIRST', AppTheme.warning),
          const SizedBox(height: 10),
          ...widget.scan.safetyWarnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 15),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(w,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tools checklist ───────────────────────────────────────────────────────

  Widget _buildToolsChecklist() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel(Icons.hardware, 'TOOLS CHECKLIST', _teal),
                Row(
                  children: [
                    if (_missingTools > 0) ...[
                      Text('$_missingTools missing',
                          style: const TextStyle(
                              color: AppTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Text('·',
                          style: TextStyle(color: AppTheme.chromeAccent)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '$_ownedTools owned',
                      style: TextStyle(
                          color: _ownedTools == _tools.length
                              ? AppTheme.success
                              : AppTheme.chromeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A3E)),
          ..._tools.asMap().entries.map((e) => _toolRow(
                index:   e.key,
                label:   e.value,
                owned:   _checkedTools.contains(e.key),
                isLast:  e.key == _tools.length - 1,
              )),
        ],
      ),
    );
  }

  Widget _toolRow({
    required int index,
    required String label,
    required bool owned,
    required bool isLast,
  }) {
    return InkWell(
      onTap: () => _toggleTool(index),
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(14))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: owned ? _teal : Colors.transparent,
                border: Border.all(
                  color: owned
                      ? _teal
                      : AppTheme.chromeAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: owned
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: owned ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                  decoration: owned ? TextDecoration.lineThrough : null,
                  decorationColor: AppTheme.textSecondary,
                ),
              ),
            ),
            if (!owned)
              const Text('Need',
                  style: TextStyle(
                      color: AppTheme.chromeAccent, fontSize: 10))
            else
              const Text('Owned',
                  style: TextStyle(color: _teal, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Steps checklist (collapsible) ─────────────────────────────────────────

  Widget _buildStepsChecklist() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel(Icons.checklist_rounded,
                    'STEP-BY-STEP GUIDE', AppTheme.electricBlue),
                Text(
                  '$_checkedItems / ${_steps.length}',
                  style: TextStyle(
                      color: _allDone
                          ? AppTheme.success
                          : AppTheme.chromeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A3E)),
          ..._steps.asMap().entries.map((e) => _stepRow(
                index: e.key,
                step:  e.value,
                done:  _checkedSteps.contains(e.key),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _stepRow({
    required int index,
    required String step,
    required bool done,
  }) {
    final isLast     = index == _steps.length - 1;
    final isExpanded = _expandedSteps.contains(index);

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpand(index),
          borderRadius: (isLast && !isExpanded)
              ? const BorderRadius.vertical(bottom: Radius.circular(14))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number / completion circle — tapping marks complete
                GestureDetector(
                  onTap: () => _toggleStep(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done
                          ? AppTheme.success.withValues(alpha: 0.15)
                          : AppTheme.electricBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: done
                          ? Border.all(color: AppTheme.success, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check,
                              color: AppTheme.success, size: 14)
                          : Text('${index + 1}',
                              style: const TextStyle(
                                  color: AppTheme.electricBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Step text (truncated when collapsed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step,
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.5,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                // Expand chevron
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.chromeAccent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded detail area
        if (isExpanded)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.04),
              borderRadius: (isLast)
                  ? const BorderRadius.vertical(bottom: Radius.circular(14))
                  : BorderRadius.zero,
            ),
            padding: const EdgeInsets.fromLTRB(56, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mark complete / undo button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleStep(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : AppTheme.electricBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: done
                                ? AppTheme.success.withValues(alpha: 0.3)
                                : AppTheme.electricBlue
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: done
                                  ? AppTheme.success
                                  : AppTheme.electricBlue,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              done ? 'Step Complete' : 'Mark Step Done',
                              style: TextStyle(
                                color: done
                                    ? AppTheme.success
                                    : AppTheme.electricBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Ask Wreniq about this step
                GestureDetector(
                  onTap: () => _openAskForStep(index, step),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.smart_toy_outlined,
                          color: _purple, size: 13),
                      SizedBox(width: 5),
                      Text('Ask Wreniq about this step',
                          style: TextStyle(
                              color: _purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: _purple)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (!isLast)
          const Divider(height: 1, indent: 56, color: Color(0xFF2A2A3E)),
      ],
    );
  }

  void _openAskForStep(int index, String step) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MechanicChatScreen(
          scan: widget.scan,
          initialMessage:
              'I\'m on Step ${index + 1} of replacing ${widget.scan.partName}: '
              '"$step" — can you help me with this?',
        ),
      ),
    );
  }

  // ── Common mistakes ───────────────────────────────────────────────────────

  Widget _buildCommonMistakes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.report_problem_outlined,
              'COMMON MISTAKES', AppTheme.warning),
          const SizedBox(height: 12),
          ..._guide.commonMistakes.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close_rounded,
                      color: AppTheme.warning, size: 15),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(m,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── When to call a mechanic ───────────────────────────────────────────────

  Widget _buildWhenToCallMechanic() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(Icons.phone_in_talk_outlined,
              'WHEN TO CALL A MECHANIC', AppTheme.electricBlue),
          const SizedBox(height: 12),
          ..._guide.whenToCallMechanic.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right,
                      color: AppTheme.electricBlue, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(w,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: AppTheme.chromeAccent, size: 15),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI may be incorrect. Verify repairs and follow proper safety procedures. '
              'Seek professionals for safety-critical repairs. '
              'Never work under a vehicle supported only by a floor jack.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Estimate Cost button ──────────────────────────────────────────────────

  Widget _buildEstimateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        onPressed: () {
          final estimate = RepairEstimateService.estimateFromScan(widget.scan);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RepairEstimateScreen(estimate: estimate),
            ),
          );
        },
        icon: const Icon(Icons.calculate_outlined, size: 18),
        label: const Text('ESTIMATE COST'),
      ),
    );
  }

  // ── Ask AI Mechanic button ────────────────────────────────────────────────

  Widget _buildAskButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MechanicChatScreen(scan: widget.scan),
          ),
        ),
        icon: const Icon(Icons.smart_toy_outlined,
            size: 18, color: _purple),
        label: const Text(
          'ASK AI MECHANIC',
          style: TextStyle(
              color: _purple,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: _purple.withValues(alpha: 0.5), width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Completion celebration dialog
// ═══════════════════════════════════════════════════════════════════════════════

class _CompletionDialog extends StatelessWidget {
  final String partName;
  final double savings;

  const _CompletionDialog({
    required this.partName,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00D4AA);

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppTheme.success, size: 46),
          ),
          const SizedBox(height: 16),
          const Text('Repair Complete!',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(partName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          if (savings > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('Estimated Labour Savings',
                      style: TextStyle(
                          color: AppTheme.chromeAccent, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '~\$${savings.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: teal,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text('vs paying a shop',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Test drive carefully and check for leaks or '
            'warning lights before returning to normal driving.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
