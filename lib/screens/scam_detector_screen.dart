import 'package:flutter/material.dart';
import '../models/repair_quote.dart';
import '../services/quote_analysis_service.dart';
import '../theme/app_theme.dart';

class ScamDetectorScreen extends StatefulWidget {
  const ScamDetectorScreen({super.key});

  @override
  State<ScamDetectorScreen> createState() => _ScamDetectorScreenState();
}

class _ScamDetectorScreenState extends State<ScamDetectorScreen> {
  final _controller = TextEditingController();
  RepairQuote? _result;
  bool _analyzing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _analyzing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _result = QuoteAnalysisService.analyze(text);
        _analyzing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SCAM DETECTOR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard(),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'Paste your repair quote here...\n\nExample:\nOil change \$89\nCabin air filter \$75\nFuel system cleaning \$120',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _analyzing ? null : _analyze,
                icon: _analyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.search, size: 18),
                label: Text(_analyzing ? 'Analyzing...' : 'Analyze Quote'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResults(_result!),
            ],
            const SizedBox(height: 20),
            _disclaimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.electricBlue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Paste a repair quote from your mechanic. Wreniq will flag overpriced items, common upsells, and unnecessary services.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(RepairQuote q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ratingCard(q),
        const SizedBox(height: 16),
        if (q.lineItems.isNotEmpty) ...[
          _sectionLabel('LINE ITEMS'),
          const SizedBox(height: 8),
          ...q.lineItems.map(_lineItemTile),
          const SizedBox(height: 16),
        ],
        if (q.redFlags.isNotEmpty) ...[
          _sectionLabel('RED FLAGS'),
          const SizedBox(height: 8),
          ...q.redFlags.map((f) =>
              _flagTile(f, AppTheme.warning, Icons.flag_rounded)),
          const SizedBox(height: 16),
        ],
        if (q.positives.isNotEmpty) ...[
          _sectionLabel('POSITIVES'),
          const SizedBox(height: 8),
          ...q.positives.map((p) =>
              _flagTile(p, AppTheme.success, Icons.check_circle_outline)),
          const SizedBox(height: 16),
        ],
        if (q.potentialSavings > 0) _savingsCard(q),
      ],
    );
  }

  Widget _ratingCard(RepairQuote q) {
    final color = _ratingColor(q.rating);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_ratingIcon(q.rating), color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.ratingLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Quoted: \$${q.totalQuoted.toStringAsFixed(0)}  •  '
                  'Fair range: \$${q.fairEstimateMin.toStringAsFixed(0)}–\$${q.fairEstimateMax.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineItemTile(QuoteLineItem item) {
    final flagged = item.isSuspicious || item.isCommonScam;
    final color = item.isCommonScam
        ? const Color(0xFFFF9500)
        : item.isSuspicious
            ? AppTheme.warning
            : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: flagged
                ? color.withValues(alpha: 0.3)
                : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.description,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(item.urgency,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Quoted: \$${item.quotedPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text(
                  'Fair: \$${item.fairMin.toStringAsFixed(0)}–\$${item.fairMax.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppTheme.chromeAccent, fontSize: 12)),
            ],
          ),
          if (flagged) ...[
            const SizedBox(height: 4),
            Text(item.explanation,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.3)),
          ],
        ],
      ),
    );
  }

  Widget _flagTile(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _savingsCard(RepairQuote q) {
    const teal = Color(0xFF00D4AA);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Potential savings: \$${q.potentialSavings.toStringAsFixed(0)} by negotiating or skipping upsell services.',
              style: const TextStyle(
                  color: teal, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
        'AI analysis only. Prices vary by region, vehicle, and shop. '
        'Always verify with certified professionals before deciding on any repairs.',
        style: TextStyle(
            color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
      ),
    );
  }

  Color _ratingColor(QuoteRating r) => switch (r) {
        QuoteRating.fair => AppTheme.success,
        QuoteRating.slightlyHigh => const Color(0xFFFF9500),
        QuoteRating.overpriced => AppTheme.warning,
        QuoteRating.suspicious => const Color(0xFFFF3B30),
      };

  IconData _ratingIcon(QuoteRating r) => switch (r) {
        QuoteRating.fair => Icons.check_circle_outline,
        QuoteRating.slightlyHigh => Icons.info_outline,
        QuoteRating.overpriced => Icons.warning_amber_rounded,
        QuoteRating.suspicious => Icons.gpp_bad_outlined,
      };

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
