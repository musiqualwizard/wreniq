import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/part_search_result.dart';
import '../models/scan_result.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../services/parts_search_service.dart';
import '../theme/app_theme.dart';

class FindPartsScreen extends StatefulWidget {
  final ScanResult scan;
  const FindPartsScreen({super.key, required this.scan});

  @override
  State<FindPartsScreen> createState() => _FindPartsScreenState();
}

class _FindPartsScreenState extends State<FindPartsScreen> {
  late final Future<List<PartSearchResult>> _searchFuture;

  static const Color _teal = Color(0xFF00D4AA);

  @override
  void initState() {
    super.initState();
    final v = context.read<VehicleProvider>().vehicle;
    _searchFuture = PartsSearchService.search(
      year:                 v?.year   ?? '',
      make:                 v?.make   ?? '',
      model:                v?.model  ?? '',
      engine:               v?.engine ?? '',   // fixed: was v?.trim
      partName:             widget.scan.partName,
      suggestedSearchTerms: widget.scan.suggestedSearchTerms,
      estimatedPriceLow:    widget.scan.estimatedPriceLow,
      estimatedPriceHigh:   widget.scan.estimatedPriceHigh,
    );
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        await Clipboard.setData(ClipboardData(text: urlString));
        _showCopiedSnackBar();
      }
    } catch (_) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: urlString));
        _showCopiedSnackBar();
      }
    }
  }

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open browser. URL copied to clipboard.'),
        backgroundColor: AppTheme.cardColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIND PARTS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<PartSearchResult>>(
        future: _searchFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
            return _buildError(snap.error?.toString());
          }
          return _buildResults(snap.data!);
        },
      ),
    );
  }

  // ── States ──────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                      color: AppTheme.electricBlue, strokeWidth: 3),
                ),
                SizedBox(height: 18),
                Text(
                  'Finding vendor search links…',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'AutoZone, O\'Reilly, Advance, NAPA, RockAuto…',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 52, color: AppTheme.chromeAccent),
            const SizedBox(height: 16),
            const Text(
              'Search unavailable',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Could not generate vendor links. Please try again.',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<PartSearchResult> results) {
    final v = context.watch<VehicleProvider>().vehicle;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(v),
        const SizedBox(height: 16),
        _buildLinksBanner(),
        const SizedBox(height: 14),
        Text(
          'RESULTS FROM ${results.length} VENDORS',
          style: const TextStyle(
            color: AppTheme.chromeAccent,
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...results.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCard(r),
            )),
        const SizedBox(height: 6),
        _buildDisclaimer(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(Vehicle? vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search, color: AppTheme.electricBlue, size: 15),
              SizedBox(width: 7),
              Text('SEARCHING FOR',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.scan.partName,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          if (vehicle != null) ...[
            const SizedBox(height: 4),
            Text(
              vehicle.fullDisplayName,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinksBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _teal.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.open_in_new, color: _teal, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap "Search Store" to open live vendor pages. Verify prices and fitment on each site.',
              style: TextStyle(color: _teal, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(PartSearchResult r) {
    final color = _storeColor(r.storeName);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.storeName,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
                if (r.isLiveLink)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _teal.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, color: _teal, size: 10),
                        SizedBox(width: 4),
                        Text(
                          'Live search link',
                          style: TextStyle(
                              color: _teal,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Part title
                Text(
                  r.partTitle,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
                const SizedBox(height: 10),

                // Price / pricing note
                Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppTheme.chromeAccent, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      r.estimatedPrice,
                      style: const TextStyle(
                          color: AppTheme.chromeAccent,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Chips row: condition + stock
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(
                      label: r.condition,
                      color: r.condition.toLowerCase().startsWith('new')
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                    _chip(
                      label: r.stockStatus,
                      color: _stockColor(r.stockStatus),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Shipping / pickup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        color: AppTheme.chromeAccent, size: 14),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        r.shippingOrPickup,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),

                // Notes
                if (r.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_outlined,
                          color: AppTheme.chromeAccent, size: 14),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          r.notes,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Search Store button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: r.productUrl.isNotEmpty
                        ? () => _openUrl(r.productUrl)
                        : null,
                    icon: Icon(Icons.open_in_new, size: 15, color: color),
                    label: Text(
                      'SEARCH STORE',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

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
              Icon(Icons.shield_outlined, color: AppTheme.chromeAccent, size: 15),
              SizedBox(width: 8),
              Text('PURCHASING DISCLAIMER',
                  style: TextStyle(
                      color: AppTheme.chromeAccent,
                      fontSize: 10,
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
                      style: TextStyle(color: AppTheme.chromeAccent, fontSize: 13)),
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _storeColor(String storeName) {
    final name = storeName.toLowerCase();
    if (name.contains('autozone'))   return AppTheme.warning;
    if (name.contains("o'reilly"))  return const Color(0xFFFF4444);
    if (name.contains('advance'))    return const Color(0xFFFF6B00);
    if (name.contains('napa'))       return const Color(0xFF4A9EFF);
    if (name.contains('rockauto'))   return AppTheme.success;
    if (name.contains('ebay'))       return AppTheme.electricBlue;
    if (name.contains('amazon'))     return const Color(0xFFFF9900);
    if (name.contains('walmart'))    return const Color(0xFF0096D6);
    if (name.contains('car-part'))   return const Color(0xFF00D4AA);
    return AppTheme.chromeAccent;
  }

  Color _stockColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('in stock'))     return AppTheme.success;
    if (s.contains('low stock'))    return AppTheme.warning;
    if (s.contains('ships'))        return AppTheme.electricBlue;
    if (s.contains('multiple'))     return AppTheme.electricBlue;
    if (s.contains('check'))        return AppTheme.chromeAccent;
    return AppTheme.chromeAccent;
  }

  static const _disclaimerPoints = [
    'Wreniq opens vendor search pages. Prices, fitment, and stock must be verified on the store website.',
    'Live inventory and pricing APIs will be added in a later phase.',
    'Always verify fitment using your full VIN, year, make, model, and engine before purchasing.',
    'Used and salvage parts carry additional risk. Inspect photos and confirm the OEM part number before ordering.',
    'Wreniq by Digiscope is not affiliated with any listed retailer and earns no commission on purchases.',
  ];
}
