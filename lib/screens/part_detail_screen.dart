import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/visual_part.dart';
import '../services/beginner_mode_service.dart';
import '../theme/app_theme.dart';

class PartDetailScreen extends StatelessWidget {
  final VisualPartResult result;
  const PartDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final beginner = context.watch<BeginnerModeService>().enabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PART DETAILS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(context, beginner),
            const SizedBox(height: 16),
            _buildUrgencyRow(),
            const SizedBox(height: 16),
            _buildWhatItDoes(beginner),
            const SizedBox(height: 16),
            _buildSymptoms(beginner),
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 16),
            _buildVideos(context),
            const SizedBox(height: 16),
            _buildSafetyWarnings(),
            const SizedBox(height: 16),
            _buildDisclaimer(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool beginner) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (File(result.imagePath).existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(
                File(result.imagePath),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.partName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _ConfidenceBadge(confidence: result.confidence),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.urgencyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: result.urgencyColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(result.urgencyIcon, color: result.urgencyColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URGENCY', style: TextStyle(color: AppTheme.chromeAccent, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(result.urgency,
                  style: TextStyle(color: result.urgencyColor, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatItDoes(bool beginner) {
    final text = beginner ? result.beginnerExplanation : result.whatItDoes;
    return _Section(
      title: beginner ? 'WHAT DOES THIS DO?' : 'FUNCTION',
      icon: Icons.info_outline,
      child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6)),
    );
  }

  Widget _buildSymptoms(bool beginner) {
    if (result.symptoms.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: beginner ? 'SIGNS SOMETHING IS WRONG' : 'COMMON SYMPTOMS',
      icon: Icons.warning_amber_outlined,
      child: Column(
        children: result.symptoms.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.fiber_manual_record, size: 8, color: AppTheme.electricBlue.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Expanded(child: Text(s, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'PRICE RANGE',
          value: result.priceRange,
          icon: Icons.attach_money,
          color: AppTheme.electricBlue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'DIY DIFFICULTY',
          value: result.diyDifficulty,
          icon: Icons.build_outlined,
          color: _difficultyColor(result.diyDifficulty),
        )),
      ],
    );
  }

  Widget _buildVideos(BuildContext context) {
    if (result.videoSearchTerms.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'HELPFUL VIDEOS',
      icon: Icons.play_circle_outline,
      child: Column(
        children: result.videoSearchTerms.take(3).map((term) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _searchYouTube(term),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, color: Color(0xFFFF0000), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(term, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  ),
                  const Icon(Icons.open_in_new, color: AppTheme.chromeAccent, size: 14),
                ],
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSafetyWarnings() {
    if (result.safetyWarnings.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'SAFETY WARNINGS',
      icon: Icons.shield_outlined,
      color: const Color(0xFFFFB800),
      child: Column(
        children: result.safetyWarnings.map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFFB800)),
              const SizedBox(width: 8),
              Expanded(child: Text(w, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'DISCLAIMER: AI part identification is for informational purposes only. Results may be inaccurate. '
        'Always verify identification and repairs with a qualified mechanic. '
        'Never attempt repairs that exceed your skill level. '
        'Always use proper safety equipment.',
        style: TextStyle(color: AppTheme.chromeAccent, fontSize: 11, height: 1.5),
      ),
    );
  }

  static void _searchYouTube(String term) async {
    final query = Uri.encodeComponent(term);
    final url   = Uri.parse('https://www.youtube.com/results?search_query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Color _difficultyColor(String d) {
    switch (d) {
      case 'Beginner':     return const Color(0xFF00E676);
      case 'Advanced':     return const Color(0xFFFF3B30);
      default:             return const Color(0xFFFFB800);
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Widget   child;
  final Color    color;
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.color = AppTheme.electricBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: color, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 10, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct   = (confidence * 100).toStringAsFixed(0);
    final color = confidence >= 0.7
        ? AppTheme.success
        : confidence >= 0.4
            ? const Color(0xFFFFB800)
            : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$pct% match', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

