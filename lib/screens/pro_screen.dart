import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  static const _gold   = Color(0xFFFFB800);
  static const _purple = Color(0xFF9C6FFF);
  static const _teal   = Color(0xFF00D4AA);
  static const _green  = Color(0xFF30D158);

  // ── Feature list ─────────────────────────────────────────────────────────────

  static const _features = [
    (Icons.all_inclusive_rounded,      'Unlimited AI Part Scans'),
    (Icons.electrical_services,        'Advanced OBD2 Diagnostics'),
    (Icons.calculate_outlined,         'Repair Cost Estimator'),
    (Icons.smart_toy_outlined,         'AI Mechanic Chat'),
    (Icons.garage_outlined,            'Saved Garage History'),
    (Icons.speed_rounded,              'Live OBD2 Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: AppTheme.chromeAccent, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                _buildFeatureList(),
                const SizedBox(height: 28),
                _buildPricingCards(),
                const SizedBox(height: 24),
                _buildCta(context),
                const SizedBox(height: 12),
                _buildDevSection(context),
                const SizedBox(height: 16),
                _buildDisclaimer(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withValues(alpha: 0.25),
            AppTheme.electricBlue.withValues(alpha: 0.15),
            _teal.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          // Crown icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: _gold, size: 40),
          ),
          const SizedBox(height: 20),
          // Title
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [_purple, AppTheme.electricBlue, _teal],
            ).createShader(r),
            child: const Text(
              'WRENIQ PRO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Full AI automotive intelligence.\nUnlimited. No compromise.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Feature list ──────────────────────────────────────────────────────────────

  Widget _buildFeatureList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: _features.asMap().entries.map((e) {
          final isLast = e.key == _features.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(e.value.$1, color: _teal, size: 17),
                ),
                title: Text(
                  e.value.$2,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.check_circle_rounded,
                    color: _green, size: 18),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppTheme.chromeAccent.withValues(alpha: 0.1)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Pricing cards ─────────────────────────────────────────────────────────────

  Widget _buildPricingCards() {
    return Row(
      children: [
        Expanded(child: _pricingCard(
          label: 'MONTHLY',
          price: '\$4.99',
          period: 'per month',
          accent: AppTheme.electricBlue,
          badge: null,
        )),
        const SizedBox(width: 12),
        Expanded(child: _pricingCard(
          label: 'YEARLY',
          price: '\$39.99',
          period: 'per year',
          accent: _purple,
          badge: 'BEST VALUE',
          sublabel: 'Save 33%',
        )),
      ],
    );
  }

  Widget _pricingCard({
    required String label,
    required String price,
    required String period,
    required Color accent,
    required String? badge,
    String? sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: badge != null ? 0.5 : 0.2),
          width: badge != null ? 1.5 : 1,
        ),
        boxShadow: badge != null
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            )
          else
            const SizedBox(height: 21),
          Text(label,
              style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(price,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          Text(period,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(sublabel,
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  // ── CTA button ────────────────────────────────────────────────────────────────

  Widget _buildCta(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premium, _) {
        if (premium.isPro) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: _green, size: 20),
                SizedBox(width: 10),
                Text('Wreniq Pro is Active',
                    style: TextStyle(
                        color: _green,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
              elevation: 0,
            ),
            onPressed: () {
              premium.activateDemoPro();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wreniq Pro activated (demo mode)!'),
                  backgroundColor: Color(0xFF30D158),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium_rounded, size: 20),
            label: const Text('START DEMO PRO'),
          ),
        );
      },
    );
  }

  // ── Dev section ───────────────────────────────────────────────────────────────

  Widget _buildDevSection(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premium, _) {
        if (!premium.isPro) return const SizedBox.shrink();
        return Center(
          child: TextButton.icon(
            onPressed: () {
              premium.deactivateDemoPro();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demo Pro deactivated.'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            },
            icon: const Icon(Icons.developer_mode_rounded,
                size: 14, color: AppTheme.chromeAccent),
            label: const Text('Deactivate Demo Pro',
                style: TextStyle(
                    color: AppTheme.chromeAccent, fontSize: 12)),
          ),
        );
      },
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.chromeAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Billing will be connected in a later phase. '
                  '"Start Demo Pro" activates Pro features locally for testing only.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Placeholder prices shown. Actual pricing subject to change.',
            style: TextStyle(
                color: AppTheme.chromeAccent.withValues(alpha: 0.6),
                fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
