import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_result.dart';
import '../providers/vehicle_provider.dart';
import '../providers/scan_provider.dart';
import '../theme/app_theme.dart';
import 'garage_screen.dart';
import 'mechanic_chat_screen.dart';
import 'live_dashboard_screen.dart';
import 'obd_screen.dart';
import 'scan_screen.dart';
import 'saved_scans_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildVehicleCard(context),
                  const SizedBox(height: 28),
                  _sectionLabel('Quick Actions'),
                  const SizedBox(height: 14),
                  _buildActionsGrid(context),
                  const SizedBox(height: 12),
                  _buildDiagnosticsCard(context),
                  const SizedBox(height: 12),
                  _buildLiveDashboardCard(context),
                  const SizedBox(height: 28),
                  _buildRecentScans(context),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.electricBlue, width: 1.5),
              boxShadow: [
                BoxShadow(color: AppTheme.electricBlue.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.car_repair, color: AppTheme.electricBlue, size: 22),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AppTheme.electricBlue, AppTheme.chrome],
            ).createShader(r),
            child: const Text(
              'WRENIQ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.chromeAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle Card ─────────────────────────────────────────────────────────────

  Widget _buildVehicleCard(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vp, _) {
        if (vp.isLoading) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return vp.hasVehicle
            ? _vehicleSetCard(context, vp)
            : _vehicleEmptyCard(context);
      },
    );
  }

  Widget _vehicleEmptyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GarageScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_car_outlined, color: AppTheme.electricBlue, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Vehicle Set Up',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap to add your vehicle for accurate part matching',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.electricBlue, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _vehicleSetCard(BuildContext context, VehicleProvider vp) {
    final v = vp.vehicle!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: AppTheme.electricBlue.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppTheme.electricBlue, size: 16),
              const SizedBox(width: 8),
              const Text('YOUR VEHICLE',
                  style: TextStyle(color: AppTheme.electricBlue, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GarageScreen()),
                ),
                child: const Text('GARAGE',
                    style: TextStyle(color: AppTheme.electricBlue, fontSize: 11, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${v.year} ${v.make}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
          Text('${v.model}  •  ${v.trim}',
              style: const TextStyle(color: AppTheme.chromeAccent, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Actions Grid ─────────────────────────────────────────────────────────────

  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _actionCard(
          context,
          icon: Icons.camera_alt_outlined,
          label: 'Scan Part',
          sublabel: 'AI identification',
          color: AppTheme.electricBlue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
        ),
        _actionCard(
          context,
          icon: Icons.history,
          label: 'Saved Scans',
          sublabel: 'View history',
          color: const Color(0xFF9C6FFF),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedScansScreen())),
        ),
        _actionCard(
          context,
          icon: Icons.smart_toy_outlined,
          label: 'Ask Wreniq',
          sublabel: 'AI mechanic chat',
          color: const Color(0xFF9C6FFF),
          onTap: () {
            final vp = Provider.of<VehicleProvider>(context, listen: false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MechanicChatScreen(
                  vehicleInfo: vp.vehicle?.displayName,
                ),
              ),
            );
          },
        ),
        _actionCard(
          context,
          icon: Icons.garage_outlined,
          label: 'My Garage',
          sublabel: 'Manage vehicles',
          color: const Color(0xFF9C6FFF),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const GarageScreen())),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sublabel,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Diagnostics Feature Card ──────────────────────────────────────────────────

  Widget _buildDiagnosticsCard(BuildContext context) {
    const amber = Color(0xFFFF9500);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OBDScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: amber.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.electrical_services, color: amber, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Diagnostics',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Read OBD2 fault codes',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'OBD2',
                style: TextStyle(
                    color: amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.chromeAccent, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Live Dashboard Feature Card ──────────────────────────────────────────────

  Widget _buildLiveDashboardCard(BuildContext context) {
    const teal = Color(0xFF00D4AA);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveDashboardScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: teal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.speed_rounded, color: teal, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Vehicle Data',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time engine metrics',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                    color: teal,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.chromeAccent, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Recent Scans ─────────────────────────────────────────────────────────────

  Widget _buildRecentScans(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, sp, _) {
        final scans = sp.savedScans.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _sectionLabel('Recent Scans')),
                if (scans.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedScansScreen()),
                    ),
                    child: const Text('See All',
                        style: TextStyle(color: AppTheme.electricBlue, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (scans.isEmpty) _emptyScansPlaceholder(),
            ...scans.map(_recentScanTile),
          ],
        );
      },
    );
  }

  Widget _emptyScansPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.camera_alt_outlined, color: AppTheme.chromeAccent, size: 36),
            SizedBox(height: 8),
            Text('No scans yet', style: TextStyle(color: AppTheme.chromeAccent)),
            SizedBox(height: 2),
            Text('Scan a car part to get started',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _recentScanTile(ScanResult scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.car_repair, color: AppTheme.electricBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.partName,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text(scan.vehicleInfo,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(scan.confidenceScore * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: AppTheme.electricBlue, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.chromeAccent,
        fontSize: 12,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
