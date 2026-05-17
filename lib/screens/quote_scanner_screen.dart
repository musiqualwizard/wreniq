import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/repair_quote.dart';
import '../services/quote_analysis_service.dart';
import '../theme/app_theme.dart';

class QuoteScannerScreen extends StatefulWidget {
  const QuoteScannerScreen({super.key});

  @override
  State<QuoteScannerScreen> createState() => _QuoteScannerScreenState();
}

class _QuoteScannerScreenState extends State<QuoteScannerScreen> {
  // 0 = photo mode, 1 = text mode
  int _mode = 0;

  XFile? _image;
  final _textCtrl = TextEditingController();
  RepairQuote? _result;
  bool _analyzing = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1400,
    );
    if (file != null && mounted) {
      setState(() {
        _image  = file;
        _result = null;
      });
    }
  }

  void _analyze() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _image == null) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please type the repair items from your quote so Wreniq can analyse them.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _analyzing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _result   = QuoteAnalysisService.analyze(text);
        _analyzing = false;
      });
      if (_result != null) HapticFeedback.heavyImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUOTE SCANNER')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modeSelector(),
            const SizedBox(height: 16),
            if (_mode == 0) _imageSection() else _textSection(),
            const SizedBox(height: 16),
            _analyzeButton(),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResults(_result!),
            ],
            const SizedBox(height: 20),
            _disclaimer(),
          ],
        ),
      ),
    );
  }

  // ── Mode selector ─────────────────────────────────────────────────────────

  Widget _modeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _modeTab(0, Icons.photo_camera_outlined, 'Scan Photo'),
          _modeTab(1, Icons.text_fields_outlined, 'Paste Text'),
        ],
      ),
    );
  }

  Widget _modeTab(int index, IconData icon, String label) {
    final active = _mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _mode   = index;
            _result = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                active ? AppTheme.electricBlue.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? AppTheme.electricBlue
                      : AppTheme.chromeAccent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? AppTheme.electricBlue
                      : AppTheme.chromeAccent,
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image section ─────────────────────────────────────────────────────────

  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ocrReadyBanner(),
        const SizedBox(height: 14),
        _imagePreviewArea(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _photoButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _photoButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'ADD REPAIR ITEMS',
          style: TextStyle(
              color: AppTheme.chromeAccent,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: _image != null
                ? 'Photo attached. Type the repair items and prices from your quote:\n\nOil change \$89\nBrake pads \$280'
                : 'Take a photo of your quote, then type the key items here for analysis.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _ocrReadyBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF9C6FFF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF9C6FFF).withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined,
              color: Color(0xFF9C6FFF), size: 15),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Photo upload ready. Auto-extract (OCR) is coming in the next update — '
              'for now, snap the quote and type the key items below.',
              style: TextStyle(
                  color: Color(0xFF9C6FFF), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreviewArea() {
    if (_image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(_image!.path),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _image = null);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.2),
            style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 40,
              color: AppTheme.electricBlue.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          const Text('Tap Gallery or Camera to attach quote',
              style:
                  TextStyle(color: AppTheme.chromeAccent, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.electricBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.electricBlue, size: 18),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Text section ──────────────────────────────────────────────────────────

  Widget _textSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.electricBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.electricBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined,
                  color: AppTheme.electricBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paste or type your repair quote. Wreniq will flag overpriced items, '
                  'common upsells, and suggest where you can save.',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _textCtrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText:
                'Paste your repair quote here...\n\nExample:\nOil change \$89\nCabin air filter \$75\nFuel system cleaning \$120\nBrake pads front \$280',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ── Analyze button ────────────────────────────────────────────────────────

  Widget _analyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _analyzing ? null : _analyze,
        icon: _analyzing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.search, size: 18),
        label: Text(_analyzing ? 'Analyzing...' : 'Analyze Quote'),
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

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
          ...q.redFlags
              .map((f) => _flagTile(f, AppTheme.warning, Icons.flag_rounded)),
          const SizedBox(height: 16),
        ],
        if (q.positives.isNotEmpty) ...[
          _sectionLabel('POSITIVES'),
          const SizedBox(height: 8),
          ...q.positives.map(
              (p) => _flagTile(p, AppTheme.success, Icons.check_circle_outline)),
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
                Text(
                  q.ratingLabel,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quoted: \$${q.totalQuoted.toStringAsFixed(0)}  '
                  '·  Fair: \$${q.fairEstimateMin.toStringAsFixed(0)}–\$${q.fairEstimateMax.toStringAsFixed(0)}',
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
    final color   = item.isCommonScam
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
            color: flagged ? color.withValues(alpha: 0.3) : Colors.transparent),
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
              Text(
                'Quoted: \$${item.quotedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Text(
                'Fair: ${item.fairRange}',
                style: const TextStyle(
                    color: AppTheme.chromeAccent, fontSize: 12),
              ),
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
              'Potential savings: \$${q.potentialSavings.toStringAsFixed(0)} '
              'by negotiating or skipping unnecessary upsell services.',
              style: const TextStyle(
                  color: teal, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'AI estimate only. Prices vary by region, vehicle, and shop. '
        'Always verify with certified professionals before deciding on repairs.',
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

  Color _ratingColor(QuoteRating r) => switch (r) {
        QuoteRating.fair        => AppTheme.success,
        QuoteRating.slightlyHigh => const Color(0xFFFF9500),
        QuoteRating.overpriced   => AppTheme.warning,
        QuoteRating.suspicious   => const Color(0xFFFF3B30),
      };

  IconData _ratingIcon(QuoteRating r) => switch (r) {
        QuoteRating.fair        => Icons.check_circle_outline,
        QuoteRating.slightlyHigh => Icons.info_outline,
        QuoteRating.overpriced   => Icons.warning_amber_rounded,
        QuoteRating.suspicious   => Icons.gpp_bad_outlined,
      };
}
