import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_result.dart';
import '../models/vehicle_health.dart';
import '../providers/maintenance_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/vehicle_health_provider.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_theme.dart';
import 'diy_videos_screen.dart';
import 'emergency_mode_screen.dart';
import 'garage_screen.dart';
import 'live_dashboard_screen.dart';
import 'maintenance_timeline_screen.dart';
import 'mechanic_chat_screen.dart';
import 'obd_screen.dart';
import 'recall_alerts_screen.dart';
import 'saved_scans_screen.dart';
import 'scan_screen.dart';
import 'scam_detector_screen.dart';
import 'settings_screen.dart';
import 'sound_diagnosis_screen.dart';

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
                  const SizedBox(height: 16),
                  _buildHealthCard(context),
                  const SizedBox(height: 16),
                  _buildSmartAlerts(context),
                  const SizedBox(height: 16),
                  _buildStreakRow(context),
                  const SizedBox(height: 28),
                  _sectionLabel('Quick Actions'),
                  const SizedBox(height: 14),
                  _buildActionsGrid(context),
                  const SizedBox(height: 12),
                  _buildDiagnosticsCard(context),
                  const SizedBox(height: 12),
                  _buildLiveDashboardCard(context),
                  const SizedBox(height: 12),
                  _buildMaintenanceCard(context),
                  const SizedBox(height: 12),
                  _buildDiyVideosCard(context),
                  const SizedBox(height: 12),
                  _buildEmergencyCard(context),
                  const SizedBox(height: 12),
                  _buildScamDetectorCard(context),
                  const SizedBox(height: 12),
                  _buildSoundDiagnosisCard(context),
                  const SizedBox(height: 12),
                  _buildRecallAlertsCard(context),
                  const SizedBox(height: 28),
                  _buildSavingsCard(context),
                  const SizedBox(height: 28),
                  _buildRecentScans(context),
                  const SizedBox(height: 20),
                  _buildFooterDisclaimer(),
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
                BoxShadow(
                    color: AppTheme.electricBlue.withValues(alpha: 0.3),
                    blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.car_repair,
                color: AppTheme.electricBlue, size: 22),
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
            icon: const Icon(Icons.settings_outlined,
                color: AppTheme.chromeAccent),
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
              child: Center(child: CircularProgressIndicator()));
        }
        return vp.hasVehicle
            ? _vehicleSetCard(context, vp)
            : _vehicleEmptyCard(context);
      },
    );
  }

  Widget _vehicleEmptyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const GarageScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.electricBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_car_outlined,
                  color: AppTheme.electricBlue, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Vehicle Set Up',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap to add your vehicle for accurate part matching',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.electricBlue, size: 16),
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
        border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car,
                  color: AppTheme.electricBlue, size: 16),
              const SizedBox(width: 8),
              const Text('YOUR VEHICLE',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GarageScreen())),
                child: const Text('GARAGE',
                    style: TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 11,
                        letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${v.year} ${v.make}',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          Text('${v.model}  •  ${v.trim}',
              style: const TextStyle(
                  color: AppTheme.chromeAccent, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Vehicle Health Card ───────────────────────────────────────────────────────

  Widget _buildHealthCard(BuildContext context) {
    return Consumer<VehicleHealthProvider>(
      builder: (context, hp, _) {
        final h = hp.health;
        final color = _healthColor(h.status);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_outline, color: color, size: 16),
                  const SizedBox(width: 8),
                  const Text('VEHICLE HEALTH',
                      style: TextStyle(
                          color: AppTheme.chromeAccent,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(h.statusLabel,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Score circle
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: h.score / 100,
                          strokeWidth: 6,
                          backgroundColor:
                              color.withValues(alpha: 0.15),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                        Center(
                          child: Text(
                            '${h.score}',
                            style: TextStyle(
                                color: color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (h.issues.isNotEmpty)
                          ...h.issues.map((i) => _bulletItem(
                              i, AppTheme.warning, Icons.warning_amber_rounded))
                        else
                          ...h.positives.take(3).map((p) =>
                              _bulletItem(p, color, Icons.check_circle_outline)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bulletItem(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color == AppTheme.warning
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _healthColor(HealthStatus s) => switch (s) {
    HealthStatus.excellent => AppTheme.success,
    HealthStatus.good      => AppTheme.electricBlue,
    HealthStatus.warning   => const Color(0xFFFF9500),
    HealthStatus.critical  => AppTheme.warning,
  };

  // ── Smart Alerts ──────────────────────────────────────────────────────────────

  Widget _buildSmartAlerts(BuildContext context) {
    return Consumer2<VehicleHealthProvider, MaintenanceProvider>(
      builder: (context, hp, mp, _) {
        final alerts = _buildAlertList(hp, mp);
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Smart Alerts'),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: alerts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => alerts[i],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAlertList(
      VehicleHealthProvider hp, MaintenanceProvider mp) {
    final list = <Widget>[];

    for (final issue in hp.health.issues) {
      list.add(_AlertCard(
        icon: Icons.warning_amber_rounded,
        title: 'Health Alert',
        body: issue,
        color: AppTheme.warning,
      ));
    }

    for (final e in mp.overdueEvents) {
      list.add(_AlertCard(
        icon: Icons.schedule,
        title: 'Maintenance Overdue',
        body: e.title,
        color: const Color(0xFFFF9500),
      ));
    }

    for (final e in mp.upcomingEvents) {
      list.add(_AlertCard(
        icon: Icons.notifications_outlined,
        title: 'Due Soon',
        body: e.title,
        color: AppTheme.electricBlue,
      ));
    }

    // Fallback demo alerts when no real data yet
    if (list.isEmpty && hp.health.score >= 85) {
      list.add(const _AlertCard(
        icon: Icons.check_circle_outline,
        title: 'All Clear',
        body: 'No active alerts',
        color: AppTheme.success,
      ));
    }

    return list;
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
        _actionCard(context,
            icon: Icons.camera_alt_outlined,
            label: 'Scan Part',
            sublabel: 'AI identification',
            color: AppTheme.electricBlue,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScanScreen()))),
        _actionCard(context,
            icon: Icons.history,
            label: 'Saved Scans',
            sublabel: 'View history',
            color: const Color(0xFF9C6FFF),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavedScansScreen()))),
        _actionCard(context,
            icon: Icons.smart_toy_outlined,
            label: 'Ask Wreniq',
            sublabel: 'AI mechanic chat',
            color: const Color(0xFF9C6FFF),
            onTap: () {
              final vp =
                  Provider.of<VehicleProvider>(context, listen: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MechanicChatScreen(
                    vehicleInfo: vp.vehicle?.displayName,
                  ),
                ),
              );
            }),
        _actionCard(context,
            icon: Icons.garage_outlined,
            label: 'My Garage',
            sublabel: 'Manage vehicles',
            color: const Color(0xFF9C6FFF),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GarageScreen()))),
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
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(sublabel,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature Cards ─────────────────────────────────────────────────────────────

  Widget _buildDiagnosticsCard(BuildContext context) {
    const amber = Color(0xFFFF9500);
    return _featureCard(
      context,
      icon: Icons.electrical_services,
      title: 'Vehicle Diagnostics',
      subtitle: 'Read OBD2 fault codes',
      badge: 'OBD2',
      color: amber,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const OBDScreen())),
    );
  }

  Widget _buildLiveDashboardCard(BuildContext context) {
    const teal = Color(0xFF00D4AA);
    return _featureCard(
      context,
      icon: Icons.speed_rounded,
      title: 'Live Vehicle Data',
      subtitle: 'Real-time engine metrics',
      badge: 'LIVE',
      color: teal,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LiveDashboardScreen())),
    );
  }

  Widget _buildMaintenanceCard(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, mp, _) {
        final overdue = mp.overdueEvents.length;
        const purple = Color(0xFF9C6FFF);
        return _featureCard(
          context,
          icon: Icons.history_outlined,
          title: 'Maintenance Timeline',
          subtitle: overdue > 0
              ? '$overdue overdue — tap to review'
              : 'Track oil changes, brakes & more',
          badge: overdue > 0 ? '$overdue DUE' : 'TRACK',
          color: overdue > 0 ? AppTheme.warning : purple,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const MaintenanceTimelineScreen())),
        );
      },
    );
  }

  Widget _buildDiyVideosCard(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vp, _) {
        const color = Color(0xFFFF6B35);
        return _featureCard(
          context,
          icon: Icons.ondemand_video_outlined,
          title: 'DIY Video Hub',
          subtitle: 'Watch repair tutorials for your car',
          badge: 'DIY',
          color: color,
          onTap: () {
            final v = vp.vehicle;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiyVideosScreen(
                  year:      v?.year  ?? '',
                  make:      v?.make  ?? '',
                  model:     v?.model ?? '',
                  partName:  'General Repair',
                  difficulty: 'Beginner',
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Streak Row ────────────────────────────────────────────────────────────────

  Widget _buildStreakRow(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, sp, _) {
        if (sp.isLoading) return const SizedBox.shrink();
        final d = sp.data;
        if (d.currentStreak == 0 && d.totalScans == 0) return const SizedBox.shrink();

        return Row(
          children: [
            _statChip(
              icon: Icons.local_fire_department,
              label: '${d.currentStreak}-day streak',
              color: const Color(0xFFFF6B35),
            ),
            const SizedBox(width: 8),
            _statChip(
              icon: Icons.camera_alt_outlined,
              label: '${d.totalScans} scan${d.totalScans != 1 ? 's' : ''}',
              color: AppTheme.electricBlue,
            ),
            const SizedBox(width: 8),
            _statChip(
              icon: Icons.calendar_today_outlined,
              label: '${d.totalDaysActive} day${d.totalDaysActive != 1 ? 's' : ''} active',
              color: const Color(0xFF9C6FFF),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Trust + Safety Feature Cards ──────────────────────────────────────────────

  Widget _buildEmergencyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmergencyModeScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.5)),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF3B30).withValues(alpha: 0.08),
              AppTheme.cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Color(0xFFFF3B30), size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Mode',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  SizedBox(height: 2),
                  Text('Breakdown help for 7 emergency types',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('SOS',
                  style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.chromeAccent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildScamDetectorCard(BuildContext context) {
    return _featureCard(
      context,
      icon: Icons.shield_outlined,
      title: 'Scam Detector',
      subtitle: 'Analyse repair quotes for overcharging',
      badge: 'QUOTE',
      color: AppTheme.success,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ScamDetectorScreen())),
    );
  }

  Widget _buildSoundDiagnosisCard(BuildContext context) {
    return _featureCard(
      context,
      icon: Icons.hearing,
      title: 'Sound Diagnosis',
      subtitle: 'Identify car problems by the noise',
      badge: 'AI',
      color: const Color(0xFF9C6FFF),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SoundDiagnosisScreen())),
    );
  }

  Widget _buildRecallAlertsCard(BuildContext context) {
    return _featureCard(
      context,
      icon: Icons.campaign_outlined,
      title: 'Recall Alerts',
      subtitle: 'Check for active recalls on your vehicle',
      badge: 'RECALL',
      color: const Color(0xFFFF9500),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RecallAlertsScreen())),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData      icon,
    required String        title,
    required String        subtitle,
    required String        badge,
    required Color         color,
    required VoidCallback  onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.chromeAccent, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Savings Card ──────────────────────────────────────────────────────────────

  Widget _buildSavingsCard(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, sp, _) {
        const teal = Color(0xFF00D4AA);
        // Estimate labour savings: midpoint price * 55% per DIY scan
        final total = sp.savedScans.fold<double>(0.0, (sum, s) {
          final mid = (s.estimatedPriceLow + s.estimatedPriceHigh) / 2;
          return sum + (mid > 0 ? mid * 0.55 : 80.0);
        });

        if (sp.savedScans.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: teal.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              colors: [
                teal.withValues(alpha: 0.05),
                AppTheme.cardColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_outlined,
                    color: teal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WRENIQ SAVINGS',
                      style: TextStyle(
                          color: AppTheme.chromeAccent,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You saved approximately \$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'in labour costs using Wreniq DIY guides (${sp.savedScans.length} scan${sp.savedScans.length > 1 ? 's' : ''})',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                      MaterialPageRoute(
                          builder: (_) => const SavedScansScreen()),
                    ),
                    child: const Text('See All',
                        style: TextStyle(
                            color: AppTheme.electricBlue, fontSize: 13)),
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
            Icon(Icons.camera_alt_outlined,
                color: AppTheme.chromeAccent, size: 36),
            SizedBox(height: 8),
            Text('No scans yet',
                style: TextStyle(color: AppTheme.chromeAccent)),
            SizedBox(height: 2),
            Text('Scan a car part to get started',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
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
            child: const Icon(Icons.car_repair,
                color: AppTheme.electricBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.partName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(scan.vehicleInfo,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
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
                  color: AppTheme.electricBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildFooterDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.chromeAccent, size: 14),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Do NOT use Wreniq while driving. '
                  'Pull over safely before using any feature.',
                  style: TextStyle(
                      color: AppTheme.chromeAccent,
                      fontSize: 11,
                      height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'AI results are for guidance only. Always verify repairs with a certified mechanic. '
            'Wreniq is not liable for decisions made based on AI analysis.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

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

// ── Alert Card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   body;
  final Color    color;

  const _AlertCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          Text(
            body,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 12, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
