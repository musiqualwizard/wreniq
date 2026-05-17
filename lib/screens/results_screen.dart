import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_result.dart';
import '../providers/scan_provider.dart';
import '../models/diy_video.dart';
import '../services/diy_video_service.dart';
import '../services/repair_estimate_service.dart';
import '../theme/app_theme.dart';
import 'diy_videos_screen.dart';
import 'find_parts_screen.dart';
import 'mechanic_chat_screen.dart';
import 'repair_estimate_screen.dart';
import 'repair_guide_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final ScanResult  _scan;
  late final bool        _wasMock;
  late final String?     _fallbackReason;
  late final TabController _tabs;
  bool _isSaved = false;

  static const _tabLabels = ['Parts', 'Repair Guide', 'DIY Videos', 'Estimate', 'Ask Wreniq'];

  @override
  void initState() {
    super.initState();
    final sp    = context.read<ScanProvider>();
    _scan           = sp.currentResult!;
    _wasMock        = sp.lastWasMock;
    _fallbackReason = sp.fallbackReason;
    _tabs = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
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

  // ── Scaffold ─────────────────────────────────────────────────────────────────

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
      body: Column(
        children: [
          // ── Sticky scan header ──────────────────────────────────────────────
          _buildScanHeader(),
          // ── Tab bar ─────────────────────────────────────────────────────────
          _buildTabBar(),
          // ── Tab content ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PartsTab(scan: _scan),
                _RepairGuideTab(scan: _scan),
                _DiyVideosTab(scan: _scan),
                _EstimateTab(scan: _scan, onEstimate: _openEstimate),
                _AskWreniqTab(scan: _scan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scan header (always visible above tabs) ───────────────────────────────

  Widget _buildScanHeader() {
    final file = File(_scan.imagePath);
    final pct = (_scan.confidenceScore * 100).toStringAsFixed(1);
    final confColor = _scan.confidenceScore >= 0.85
        ? AppTheme.success
        : _scan.confidenceScore >= 0.70
            ? AppTheme.electricBlue
            : AppTheme.warning;
    final isMock = _wasMock;
    final bannerColor = isMock ? AppTheme.warning : AppTheme.success;

    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: file.existsSync()
                      ? Image.file(file,
                          width: 72, height: 72, fit: BoxFit.cover)
                      : Container(
                          width: 72,
                          height: 72,
                          color: AppTheme.cardColor,
                          child: const Icon(Icons.car_repair,
                              color: AppTheme.electricBlue, size: 32),
                        ),
                ),
                const SizedBox(width: 14),
                // Part info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppTheme.electricBlue, size: 12),
                          const SizedBox(width: 5),
                          const Text('AI IDENTIFIED',
                              style: TextStyle(
                                  color: AppTheme.electricBlue,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scan.partName,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('Confidence: ',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          Text('$pct%',
                              style: TextStyle(
                                  color: confColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: _scan.confidenceScore,
                                backgroundColor: AppTheme.cardColor,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(confColor),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_scan.vehicleInfo,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Source banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isMock ? Icons.info_outline : Icons.check_circle_outline,
                    color: bannerColor,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fallbackReason != null
                          ? 'Demo result — $_fallbackReason'
                          : isMock
                              ? 'Demo result — backend not configured.'
                              : 'Wreniq AI scan complete.',
                      style: TextStyle(
                          color: bannerColor, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller:         _tabs,
        isScrollable:       true,
        tabAlignment:       TabAlignment.start,
        labelColor:         AppTheme.electricBlue,
        unselectedLabelColor: AppTheme.chromeAccent,
        indicatorColor:     AppTheme.electricBlue,
        indicatorWeight:    2,
        labelStyle:         const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        dividerColor:       const Color(0xFF1E1E2E),
        tabs:               _tabLabels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }

  void _openEstimate() {
    final estimate = RepairEstimateService.estimateFromScan(_scan);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RepairEstimateScreen(estimate: estimate)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 0 — Parts
// ═══════════════════════════════════════════════════════════════════════════════

class _PartsTab extends StatelessWidget {
  final ScanResult scan;
  const _PartsTab({required this.scan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Find Parts button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FindPartsScreen(scan: scan)),
            ),
            icon: const Icon(Icons.search),
            label: const Text('FIND PARTS FOR THIS VEHICLE'),
          ),
        ),
        const SizedBox(height: 20),

        // Compatible parts
        _SectionLabel('Compatible Part Types'),
        const SizedBox(height: 10),
        scan.compatibleParts.isEmpty
            ? const _EmptyChip('No compatible parts listed')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scan.compatibleParts.map((p) => _Chip(p)).toList(),
              ),

        if (scan.suggestedSearchTerms.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel('Suggested Search Terms'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scan.suggestedSearchTerms
                .map((t) => _SearchTermChip(t))
                .toList(),
          ),
        ],

        const SizedBox(height: 20),
        _SectionLabel('Where to Buy'),
        const SizedBox(height: 10),
        ...scan.buyOptions.map((opt) => _BuyOptionTile(opt: opt)),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1 — Repair Guide
// ═══════════════════════════════════════════════════════════════════════════════

class _RepairGuideTab extends StatelessWidget {
  final ScanResult scan;
  const _RepairGuideTab({required this.scan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Open full guide button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RepairGuideScreen(scan: scan)),
            ),
            icon: const Icon(Icons.book_outlined,
                size: 16, color: Color(0xFF00D4AA)),
            label: const Text('OPEN FULL REPAIR GUIDE',
                style: TextStyle(
                    color: Color(0xFF00D4AA),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.45),
                  width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Fitment warning
        _buildFitmentWarning(scan.fitmentWarning),
        const SizedBox(height: 20),

        // Tools
        _SectionLabel('Tools Needed'),
        const SizedBox(height: 10),
        _ToolsList(scan.toolsNeeded),

        const SizedBox(height: 20),

        // Steps
        _SectionLabel('Replacement Guide'),
        const SizedBox(height: 10),
        _RepairStepsList(scan.repairSteps),

        // Safety warnings
        if (scan.safetyWarnings.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel('Safety Warnings'),
          const SizedBox(height: 10),
          _SafetyWarningsList(scan.safetyWarnings),
        ],

        const SizedBox(height: 20),
        _DisclaimerCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFitmentWarning(String text) {
    final msg = text.isNotEmpty
        ? text
        : 'Always verify fitment using a parts store VIN lookup before purchasing.';
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
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: AppTheme.warning, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — DIY Videos
// ═══════════════════════════════════════════════════════════════════════════════

class _DiyVideosTab extends StatelessWidget {
  final ScanResult scan;
  const _DiyVideosTab({required this.scan});

  // Extract year/make/model from vehicleInfo "2013 Dodge Ram 1500, Trim/Engine: ..."
  static (String, String, String) _parseVehicle(String info) {
    final parts = info.split(' ');
    final year  = parts.isNotEmpty ? parts[0] : '';
    final make  = parts.length > 1 ? parts[1] : '';
    final model = parts.length > 2
        ? parts.sublist(2).join(' ').split(',').first.trim()
        : '';
    return (year, make, model);
  }

  @override
  Widget build(BuildContext context) {
    final (year, make, model) = _parseVehicle(scan.vehicleInfo);
    final videos = DiyVideoService.forScan(
      year:       year,
      make:       make,
      model:      model,
      partName:   scan.partName,
      difficulty: scan.repairDifficulty,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Open full hub button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiyVideosScreen(
                  year:        year,
                  make:        make,
                  model:       model,
                  partName:    scan.partName,
                  difficulty:  scan.repairDifficulty,
                  repairSteps: scan.repairSteps,
                ),
              ),
            ),
            icon: const Icon(Icons.ondemand_video_outlined),
            label: const Text('OPEN DIY VIDEO HUB'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C6FFF),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Compact preview cards
        ...videos.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _VideoPreviewTile(video: v),
        )),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _VideoPreviewTile extends StatelessWidget {
  final DiyVideo video;
  const _VideoPreviewTile({required this.video});

  Color get _diffColor => switch (video.difficulty) {
    'Beginner'     => const Color(0xFF00E676),
    'Intermediate' => const Color(0xFF00B4FF),
    _              => const Color(0xFFFF9500),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_circle_outline,
                color: AppTheme.electricBlue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(video.channelName,
                        style: const TextStyle(
                            color: AppTheme.chromeAccent, fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _diffColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(video.difficulty,
                          style: TextStyle(
                              color: _diffColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppTheme.chromeAccent, size: 13),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 3 — Estimate
// ═══════════════════════════════════════════════════════════════════════════════

class _EstimateTab extends StatelessWidget {
  final ScanResult     scan;
  final VoidCallback   onEstimate;
  const _EstimateTab({required this.scan, required this.onEstimate});

  @override
  Widget build(BuildContext context) {
    final diffColor = scan.repairDifficulty == 'Beginner'
        ? AppTheme.success
        : scan.repairDifficulty == 'Intermediate'
            ? AppTheme.electricBlue
            : AppTheme.warning;
    const teal = Color(0xFF00D4AA);

    // Estimated DIY savings (labour avoided ≈ 55% of midpoint estimate)
    final midpoint = (scan.estimatedPriceLow + scan.estimatedPriceHigh) / 2;
    final savings  = (midpoint * 0.55).clamp(0, 9999);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Price + difficulty tiles
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.attach_money,
                label: 'Est. Parts Cost',
                value: scan.priceRange,
                color: teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.build_outlined,
                label: 'Difficulty',
                value: scan.repairDifficulty,
                color: diffColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // AI explanation (visible in estimate context)
        if (scan.explanation.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.electricBlue.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_outlined,
                        color: AppTheme.electricBlue, size: 14),
                    SizedBox(width: 6),
                    Text('AI REASONING',
                        style: TextStyle(
                            color: AppTheme.electricBlue,
                            fontSize: 10,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(scan.explanation,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Savings callout
        if (savings > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: teal, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated DIY Savings',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        '~\$${savings.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: teal,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'vs paying a shop for labour',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Full estimate button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onEstimate,
            icon: const Icon(Icons.calculate_outlined, size: 18, color: teal),
            label: const Text(
              'FULL COST BREAKDOWN',
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
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 24),
        _DisclaimerCard(),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 4 — Ask Wreniq
// ═══════════════════════════════════════════════════════════════════════════════

class _AskWreniqTab extends StatelessWidget {
  final ScanResult scan;
  const _AskWreniqTab({required this.scan});

  static const _prompts = [
    'How do I replace this?',
    'What tools do I need?',
    'Is this safe to DIY?',
    'How much will this cost at a shop?',
    'What mistakes should I avoid?',
    'How long will this repair take?',
    'Are there cheaper alternatives?',
  ];

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9C6FFF);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Open chat button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MechanicChatScreen(
                  scan:        scan,
                  vehicleInfo: scan.vehicleInfo,
                ),
              ),
            ),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('OPEN FULL AI CHAT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Quick Questions',
          style: TextStyle(
              color: AppTheme.chromeAccent,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prompts.map((p) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MechanicChatScreen(
                  scan:           scan,
                  vehicleInfo:    scan.vehicleInfo,
                  initialMessage: p,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: purple, size: 13),
                  const SizedBox(width: 6),
                  Text(p,
                      style: const TextStyle(
                          color: purple,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )).toList(),
        ),

        const SizedBox(height: 24),

        // Context card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.chromeAccent, size: 14),
                  SizedBox(width: 6),
                  Text('CURRENT CONTEXT',
                      style: TextStyle(
                          color: AppTheme.chromeAccent,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              _contextRow('Part', scan.partName),
              _contextRow('Vehicle', scan.vehicleInfo),
              _contextRow('Difficulty', scan.repairDifficulty),
              _contextRow('Price range', scan.priceRange),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _contextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(
                    color: AppTheme.chromeAccent, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppTheme.chromeAccent,
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.electricBlue, fontSize: 13)),
    );
  }
}

class _SearchTermChip extends StatelessWidget {
  final String term;
  const _SearchTermChip(this.term);

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00D4AA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, color: teal, size: 13),
          const SizedBox(width: 5),
          Text(term,
              style: const TextStyle(color: teal, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyChip extends StatelessWidget {
  final String text;
  const _EmptyChip(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 13));
}

class _BuyOptionTile extends StatelessWidget {
  final BuyOption opt;
  const _BuyOptionTile({required this.opt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                color: AppTheme.electricBlue, size: 20),
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
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.electricBlue.withValues(alpha: 0.3)),
            ),
            child: const Text('VIEW',
                style: TextStyle(
                    color: AppTheme.electricBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ToolsList extends StatelessWidget {
  final List<String> tools;
  const _ToolsList(this.tools);

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) {
      return const Text('No tool list provided.',
          style: TextStyle(color: AppTheme.textSecondary));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: tools
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.hardware,
                        color: AppTheme.electricBlue, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t,
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
}

class _RepairStepsList extends StatefulWidget {
  final List<String> steps;
  const _RepairStepsList(this.steps);

  @override
  State<_RepairStepsList> createState() => _RepairStepsListState();
}

class _RepairStepsListState extends State<_RepairStepsList> {
  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const Text('No repair steps provided.',
          style: TextStyle(color: AppTheme.textSecondary));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.steps.asMap().entries.map((entry) {
          final i    = entry.key;
          final step = entry.value;
          final done = _done.contains(i);
          return GestureDetector(
            onTap: () => setState(
                () => done ? _done.remove(i) : _done.add(i)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done
                          ? AppTheme.success.withValues(alpha: 0.2)
                          : AppTheme.electricBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check,
                              color: AppTheme.success, size: 14)
                          : Text('${i + 1}',
                              style: const TextStyle(
                                  color: AppTheme.electricBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: done
                            ? AppTheme.chromeAccent
                            : AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SafetyWarningsList extends StatelessWidget {
  final List<String> warnings;
  const _SafetyWarningsList(this.warnings);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: warnings
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
            )
            .toList(),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
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
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  static const _points = [
    'AI part identification is an estimate only and can make mistakes, especially with obscure or partially visible parts.',
    'Always verify part fitment using your full VIN at an authorised parts retailer before purchasing.',
    'Do not perform repairs beyond your skill level. Brakes, steering, suspension, and fuel-system work carry serious risk.',
    'Always use proper tools and PPE. Never work under a vehicle supported only by a floor jack.',
    'Verify repairs with multiple sources and follow proper safety procedures.',
    'Wreniq by Digiscope provides information only and accepts no liability for misidentified parts or resulting damage.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppTheme.chromeAccent, size: 14),
              SizedBox(width: 8),
              Text('IMPORTANT DISCLAIMER',
                  style: TextStyle(
                      color: AppTheme.chromeAccent,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ..._points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: AppTheme.chromeAccent, fontSize: 12)),
                  Expanded(
                    child: Text(p,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
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
}
