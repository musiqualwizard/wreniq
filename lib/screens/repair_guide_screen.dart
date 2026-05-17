import 'package:flutter/material.dart';
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
  static const Color _teal = Color(0xFF00D4AA);

  Set<int> _checkedTools = {};
  Set<int> _checkedSteps = {};
  bool _isLoading = true;

  late final RepairGuideData _guide;
  late final List<String> _tools;
  late final List<String> _steps;

  @override
  void initState() {
    super.initState();
    _guide = RepairGuideService.getGuideData(
      partName:        widget.scan.partName,
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

  Future<void> _toggleTool(int i) async {
    setState(() =>
        _checkedTools.contains(i) ? _checkedTools.remove(i) : _checkedTools.add(i));
    await ChecklistService.saveCheckedTools(widget.scan.id, _checkedTools);
  }

  Future<void> _toggleStep(int i) async {
    setState(() =>
        _checkedSteps.contains(i) ? _checkedSteps.remove(i) : _checkedSteps.add(i));
    await ChecklistService.saveCheckedSteps(widget.scan.id, _checkedSteps);
  }

  Future<void> _resetProgress() async {
    await ChecklistService.clearAll(widget.scan.id);
    if (mounted) setState(() { _checkedTools = {}; _checkedSteps = {}; });
  }

  int get _totalItems   => _tools.length + _steps.length;
  int get _checkedItems => _checkedTools.length + _checkedSteps.length;
  bool get _allDone     => _totalItems > 0 && _checkedItems == _totalItems;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.electricBlue),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('REPAIR GUIDE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                    onPressed: _checkedItems > 0 ? _resetProgress : null,
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
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    final progress = _totalItems > 0 ? _checkedItems / _totalItems : 0.0;
    final barColor = _allDone ? AppTheme.success : _teal;
    final label    = _allDone
        ? 'All done!'
        : '$_checkedItems of $_totalItems items complete';

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROGRESS',
                style: TextStyle(
                    color: AppTheme.chromeAccent,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: TextStyle(
                      color: barColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
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

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final diffColor = switch (widget.scan.repairDifficulty.toLowerCase()) {
      'beginner' => AppTheme.success,
      'advanced' => AppTheme.warning,
      _          => AppTheme.electricBlue,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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
          Text(
            widget.scan.vehicleInfo,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _badge(
                icon: Icons.speed_outlined,
                label: widget.scan.repairDifficulty,
                color: diffColor,
              ),
              _badge(
                icon: Icons.access_time_outlined,
                label: _guide.estimatedTime,
                color: _teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  // ── Safety warnings ───────────────────────────────────────────────────────────

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
                  Icon(Icons.warning_amber_rounded,
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

  // ── Tools checklist ───────────────────────────────────────────────────────────

  Widget _buildToolsChecklist() {
    final checked = _checkedTools.length;
    final total   = _tools.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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
                Text(
                  '$checked / $total',
                  style: TextStyle(
                      color: checked == total
                          ? AppTheme.success
                          : AppTheme.chromeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A3E)),
          ..._tools.asMap().entries.map((e) => _checkRow(
                label:   e.value,
                checked: _checkedTools.contains(e.key),
                isLast:  e.key == _tools.length - 1,
                onTap:   () => _toggleTool(e.key),
                color:   _teal,
              )),
        ],
      ),
    );
  }

  // ── Steps checklist ───────────────────────────────────────────────────────────

  Widget _buildStepsChecklist() {
    final checked = _checkedSteps.length;
    final total   = _steps.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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
                  '$checked / $total',
                  style: TextStyle(
                      color: checked == total
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

  // ── Common mistakes ───────────────────────────────────────────────────────────

  Widget _buildCommonMistakes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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

  // ── When to call a mechanic ───────────────────────────────────────────────────

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

  // ── Disclaimer ────────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.chromeAccent, size: 15),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wreniq provides guidance only. Always use proper tools, safety '
              'equipment, and procedures. Consult a qualified mechanic if you '
              'are uncertain about any step or if the repair involves safety-'
              'critical components.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared item widgets ───────────────────────────────────────────────────────

  // Generic checkbox row (used for tools)
  Widget _checkRow({
    required String label,
    required bool checked,
    required bool isLast,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
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
                color: checked ? color : Colors.transparent,
                border: Border.all(
                  color: checked
                      ? color
                      : AppTheme.chromeAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      checked ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                  decoration:
                      checked ? TextDecoration.lineThrough : null,
                  decorationColor: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Numbered step row with animated circle
  Widget _stepRow({
    required int index,
    required String step,
    required bool done,
  }) {
    final isLast    = index == _steps.length - 1;
    final circleColor = done ? AppTheme.success : AppTheme.electricBlue;

    return InkWell(
      onTap: () => _toggleStep(index),
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(14))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: done
                    ? Border.all(color: AppTheme.success, width: 1.5)
                    : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check,
                        color: AppTheme.success, size: 14)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                            color: AppTheme.electricBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  step,
                  style: TextStyle(
                    color: done
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                    decoration:
                        done ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        onPressed: () {
          final estimate =
              RepairEstimateService.estimateFromScan(widget.scan);
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
            size: 18, color: Color(0xFF9C6FFF)),
        label: const Text(
          'ASK AI MECHANIC',
          style: TextStyle(
              color:         Color(0xFF9C6FFF),
              fontSize:      12,
              fontWeight:    FontWeight.bold,
              letterSpacing: 1),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: const Color(0xFF9C6FFF).withValues(alpha: 0.5),
              width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

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
