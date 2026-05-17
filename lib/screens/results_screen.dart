import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../services/repair_estimate_service.dart';
import '../theme/app_theme.dart';
import 'find_parts_screen.dart';
import 'mechanic_chat_screen.dart';
import 'repair_estimate_screen.dart';
import 'repair_guide_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final ScanResult _scan;
  late final bool       _wasMock;
  late final String?    _fallbackReason;
  final _scrollController = ScrollController();
  final _repairGuideKey   = GlobalKey();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    final sp    = context.read<ScanProvider>();
    _scan           = sp.currentResult!;
    _wasMock        = sp.lastWasMock;
    _fallbackReason = sp.fallbackReason;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveScan() async {
    await context.read<ScanProvider>().saveCurrentScan();
    if (!mounted) return;
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan saved!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN RESULTS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Quick bookmark in app bar — mirrors the bottom Save button
          IconButton(
            tooltip: _isSaved ? 'Saved' : 'Save scan',
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppTheme.electricBlue : AppTheme.chromeAccent,
            ),
            onPressed: _isSaved ? null : _saveScan,
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          _buildPartImage(),
          const SizedBox(height: 12),
          _buildSourceBanner(),
          const SizedBox(height: 12),
          _buildPartHeader(),
          const SizedBox(height: 14),

          // AI explanation — the "why" behind the identification
          if (_scan.explanation.isNotEmpty) ...[
            _buildExplanation(),
            const SizedBox(height: 14),
          ],

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: 10),
          _buildAskButton(),
          const SizedBox(height: 8),
          _buildEstimateButton(),
          const SizedBox(height: 20),

          // Fitment warning
          _buildFitmentWarning(),
          const SizedBox(height: 20),

          // Price + difficulty tiles
          _buildInfoRow(),
          const SizedBox(height: 20),

          // Compatible parts / search terms
          _sectionHeader('Compatible Part Types'),
          const SizedBox(height: 10),
          _buildCompatibleParts(),

          if (_scan.suggestedSearchTerms.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Suggested Search Terms'),
            const SizedBox(height: 10),
            _buildSearchTerms(),
          ],

          const SizedBox(height: 20),
          _sectionHeader('Tools Needed'),
          const SizedBox(height: 10),
          _buildToolsList(),

          const SizedBox(height: 20),
          _sectionHeader('Replacement Guide'),
          const SizedBox(height: 10),
          _buildRepairSteps(),

          const SizedBox(height: 20),
          _sectionHeader('Where to Buy'),
          const SizedBox(height: 10),
          _buildBuyOptions(),

          if (_scan.safetyWarnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Safety Warnings'),
            const SizedBox(height: 10),
            _buildSafetyWarnings(),
          ],

          const SizedBox(height: 24),
          _buildDisclaimer(),
          const SizedBox(height: 16),

          // Bottom Save button — large, prominent
          if (!_isSaved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveScan,
                icon: const Icon(Icons.save_outlined),
                label: const Text('SAVE SCAN'),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────────

  Widget _buildPartImage() {
    final file = File(_scan.imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: file.existsSync()
          ? Image.file(file, height: 220, width: double.infinity, fit: BoxFit.cover)
          : Container(
              height: 180,
              color: AppTheme.cardColor,
              child: const Center(
                child: Icon(Icons.car_repair, size: 64, color: AppTheme.electricBlue),
              ),
            ),
    );
  }

  Widget _buildPartHeader() {
    final pct = (_scan.confidenceScore * 100).toStringAsFixed(1);
    final confColor = _scan.confidenceScore >= 0.85
        ? AppTheme.success
        : _scan.confidenceScore >= 0.70
            ? AppTheme.electricBlue
            : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.electricBlue, size: 15),
              SizedBox(width: 6),
              Text('AI IDENTIFIED',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _scan.partName,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Confidence: ',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('$pct%',
                  style: TextStyle(
                      color: confColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _scan.confidenceScore,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(confColor),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vehicle: ${_scan.vehicleInfo}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Why the AI thinks this is the identified part
  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined,
                  color: AppTheme.electricBlue, size: 16),
              SizedBox(width: 8),
              Text('AI REASONING',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _scan.explanation,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  // Find Parts | Repair Guide | Save Scan
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.search,
            label: 'Find Parts',
            color: AppTheme.electricBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindPartsScreen(scan: _scan),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.build_outlined,
            label: 'Repair Guide',
            color: const Color(0xFF00D4AA),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RepairGuideScreen(scan: _scan),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
            label: _isSaved ? 'Saved' : 'Save Scan',
            color: _isSaved ? AppTheme.chromeAccent : const Color(0xFF9C6FFF),
            onTap: _isSaved ? null : _saveScan,
          ),
        ),
      ],
    );
  }

  Widget _buildAskButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MechanicChatScreen(
              scan:        _scan,
              vehicleInfo: _scan.vehicleInfo,
            ),
          ),
        ),
        icon: const Icon(Icons.smart_toy_outlined,
            size: 18, color: Color(0xFF9C6FFF)),
        label: const Text(
          'ASK ABOUT THIS PART',
          style: TextStyle(
              color:       Color(0xFF9C6FFF),
              fontSize:    12,
              fontWeight:  FontWeight.bold,
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

  Widget _buildEstimateButton() {
    const teal = Color(0xFF00D4AA);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final estimate =
              RepairEstimateService.estimateFromScan(_scan);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RepairEstimateScreen(estimate: estimate),
            ),
          );
        },
        icon: const Icon(Icons.calculate_outlined, size: 18, color: teal),
        label: const Text(
          'ESTIMATE REPAIR COST',
          style: TextStyle(
              color: teal,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: teal.withValues(alpha: 0.5), width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitmentWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _scan.fitmentWarning.isNotEmpty
                  ? _scan.fitmentWarning
                  : 'Always verify fitment using a parts store VIN lookup before purchasing.',
              style: const TextStyle(color: AppTheme.warning, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    final diffColor = _scan.repairDifficulty == 'Beginner'
        ? AppTheme.success
        : _scan.repairDifficulty == 'Intermediate'
            ? AppTheme.electricBlue
            : AppTheme.warning;

    return Row(
      children: [
        Expanded(
          child: _infoTile(
            icon: Icons.attach_money,
            label: 'Est. Price',
            value: _scan.priceRange,
            color: const Color(0xFF00D4AA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoTile(
            icon: Icons.build_outlined,
            label: 'Difficulty',
            value: _scan.repairDifficulty,
            color: diffColor,
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: color, fontSize: 10, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCompatibleParts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _scan.compatibleParts
          .map(
            (p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.electricBlue.withValues(alpha: 0.3)),
              ),
              child: Text(p,
                  style: const TextStyle(
                      color: AppTheme.electricBlue, fontSize: 13)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSearchTerms() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _scan.suggestedSearchTerms
          .map(
            (term) => GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Search: "$term"'),
                  backgroundColor: AppTheme.cardColor,
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search,
                        color: Color(0xFF00D4AA), size: 14),
                    const SizedBox(width: 5),
                    Text(term,
                        style: const TextStyle(
                            color: Color(0xFF00D4AA), fontSize: 12)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildToolsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _scan.toolsNeeded
            .map(
              (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.hardware,
                        color: AppTheme.electricBlue, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tool,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRepairSteps() {
    return Container(
      key: _repairGuideKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _scan.repairSteps.asMap().entries.map((entry) {
          final step = entry.value;
          final num  = entry.key + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.electricBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$num',
                        style: const TextStyle(
                            color: AppTheme.electricBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(step,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          height: 1.5)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBuyOptions() {
    return Column(
      children: _scan.buyOptions.map((opt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.chromeAccent.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined,
                    color: AppTheme.electricBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.store,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(opt.priceRange,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.electricBlue.withValues(alpha: 0.3)),
                ),
                child: const Text('VIEW',
                    style: TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Banner showing whether this is a real AI result or a mock/demo result
  Widget _buildSourceBanner() {
    final isMock = _wasMock;
    final color  = isMock ? AppTheme.warning : AppTheme.success;
    final icon   = isMock ? Icons.info_outline : Icons.check_circle_outline;
    final text   = _fallbackReason != null
        ? 'Demo result shown — $_fallbackReason'
        : isMock
            ? 'Demo result shown — backend not configured.'
            : 'Wreniq AI scan complete.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // Part-specific safety warnings returned by the AI
  Widget _buildSafetyWarnings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: _scan.safetyWarnings
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warning, size: 16),
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
            )
            .toList(),
      ),
    );
  }

  // Full legal-style disclaimer at the bottom of every result
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.chromeAccent, size: 16),
              SizedBox(width: 8),
              Text('IMPORTANT DISCLAIMER',
                  style: TextStyle(
                      color: AppTheme.chromeAccent,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ..._disclaimerPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(
                          color: AppTheme.chromeAccent, fontSize: 13)),
                  Expanded(
                    child: Text(point,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
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

  static const _disclaimerPoints = [
    'AI part identification is an estimate only. The model can and does make mistakes, '
        'especially with obscure, heavily corroded, or partially visible parts.',
    'Always verify part fitment using your full VIN at an authorised parts retailer '
        'before purchasing. Wrong parts can cause vehicle damage or safety hazards.',
    'Do not perform repairs beyond your skill level. Brake, steering, suspension, '
        'and fuel-system work carries serious safety risks if done incorrectly.',
    'Always use proper tools and personal protective equipment. Never work under a '
        'vehicle supported only by a floor jack.',
    'Wreniq by Digiscope provides information only and accepts no liability for '
        'misidentified parts, incorrect repairs, or resulting vehicle damage or injury.',
  ];

  Widget _sectionHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.chromeAccent,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
