import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/repair_estimate.dart';
import '../services/repair_estimate_service.dart';
import '../theme/app_theme.dart';

class RepairEstimateScreen extends StatefulWidget {
  final RepairEstimate estimate;

  const RepairEstimateScreen({super.key, required this.estimate});

  @override
  State<RepairEstimateScreen> createState() => _RepairEstimateScreenState();
}

class _RepairEstimateScreenState extends State<RepairEstimateScreen> {
  static const _teal   = Color(0xFF00D4AA);
  static const _purple = Color(0xFF9C6FFF);
  static const _amber  = Color(0xFFFF9500);
  static const _green  = Color(0xFF30D158);

  bool _isSaved = false;

  RepairEstimate get _est => widget.estimate;

  Future<void> _save() async {
    await RepairEstimateService.saveEstimate(_est);
    if (!mounted) return;
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estimate saved!'),
        backgroundColor: Color(0xFF30D158),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPAIR ESTIMATE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Saved' : 'Save estimate',
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? _teal : AppTheme.chromeAccent,
            ),
            onPressed: _isSaved ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSourceBadge(),
          const SizedBox(height: 14),
          _buildHeader(),
          const SizedBox(height: 14),
          _buildTotalCostCard(),
          const SizedBox(height: 12),
          _buildBreakdownCard(),
          const SizedBox(height: 12),
          _buildDiySavingsCard(),
          if (_est.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNotesCard(),
          ],
          const SizedBox(height: 20),
          if (!_isSaved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text('SAVE ESTIMATE'),
              ),
            ),
          const SizedBox(height: 12),
          _buildDisclaimer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Source badge ──────────────────────────────────────────────────────────────

  Widget _buildSourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mock estimate — based on average repair data. '
              'Connect backend for AI-powered estimates.',
              style: TextStyle(
                  color: AppTheme.warning, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final diffColor = switch (_est.difficulty.toLowerCase()) {
      'beginner' => _green,
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
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  color: Color(0xFF00D4AA), size: 15),
              const SizedBox(width: 6),
              const Text('COST ESTIMATE',
                  style: TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _est.partName,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3),
          ),
          if (_est.vehicleInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_est.vehicleInfo,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(
                icon: Icons.speed_outlined,
                label: _est.difficulty,
                color: diffColor,
              ),
              _badge(
                icon: Icons.access_time_outlined,
                label: '~${_formatHours(_est.laborHours)}',
                color: _teal,
              ),
              _badge(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('MMM d, yyyy').format(_est.createdAt),
                color: AppTheme.chromeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Total cost card ───────────────────────────────────────────────────────────

  Widget _buildTotalCostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _teal.withValues(alpha: 0.15),
            AppTheme.electricBlue.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL ESTIMATED COST',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            _est.totalRange,
            style: const TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            'professional shop estimate',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Cost breakdown card ───────────────────────────────────────────────────────

  Widget _buildBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowLabel(Icons.receipt_long_outlined,
              'COST BREAKDOWN', AppTheme.electricBlue),
          const SizedBox(height: 14),
          _costRow(
            label: 'Parts',
            value: _est.partsRange,
            icon: Icons.inventory_2_outlined,
            color: AppTheme.electricBlue,
          ),
          const Divider(
              height: 20, color: Color(0xFF2A2A3E), thickness: 0.5),
          _costRow(
            label: 'Labor',
            value: _est.laborRange,
            icon: Icons.engineering_outlined,
            color: _amber,
            sublabel: '~${_formatHours(_est.laborHours)} shop time',
          ),
          const Divider(
              height: 20, color: Color(0xFF2A2A3E), thickness: 0.5),
          _costRow(
            label: 'Total',
            value: _est.totalRange,
            icon: Icons.calculate_outlined,
            color: _teal,
            isBold: true,
          ),
        ],
      ),
    );
  }

  // ── DIY savings card ──────────────────────────────────────────────────────────

  Widget _buildDiySavingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowLabel(Icons.savings_outlined, 'DIY SAVINGS', _purple),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build_outlined,
                    color: Color(0xFF9C6FFF), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Save approximately ',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          TextSpan(
                            text: _est.savingsText,
                            style: const TextStyle(
                                color: Color(0xFF9C6FFF),
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: ' by doing it yourself.',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You only pay for parts: ${_est.partsRange}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Notes card ────────────────────────────────────────────────────────────────

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowLabel(Icons.notes_outlined, 'NOTES', AppTheme.chromeAccent),
          const SizedBox(height: 10),
          Text(
            _est.notes,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: AppTheme.chromeAccent, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Costs are estimates only. Actual prices vary by location, shop, '
              'parts brand, and vehicle. Always get a written quote from a '
              'qualified mechanic before authorising work.',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────────

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _rowLabel(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _costRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? sublabel,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: isBold
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: isBold ? 14 : 13,
                      fontWeight:
                          isBold ? FontWeight.w700 : FontWeight.normal)),
              if (sublabel != null)
                Text(sublabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
              color: isBold ? _teal : AppTheme.textPrimary,
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  String _formatHours(double h) {
    if (h < 1) return '${(h * 60).round()} min';
    final whole = h.truncate();
    final mins  = ((h - whole) * 60).round();
    if (mins == 0) return '${whole}h';
    return '${whole}h ${mins}m';
  }
}
