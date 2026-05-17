import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/backend_config.dart';
import '../providers/vehicle_provider.dart';
import '../providers/scan_provider.dart';
import '../services/auth_service.dart';
import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';
import 'pro_screen.dart';
import 'vehicle_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAccountSection(context),
          const SizedBox(height: 24),
          _buildProSection(context),
          const SizedBox(height: 24),
          _buildVehicleSection(context),
          const SizedBox(height: 24),
          _buildDataSection(context),
          const SizedBox(height: 24),
          _buildBackendSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(),
          const SizedBox(height: 32),
          _buildVersion(),
        ],
      ),
    );
  }

  // ── Account ───────────────────────────────────────────────────────────────────

  Widget _buildAccountSection(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return const SizedBox.shrink();
        final user = auth.currentUser!;
        return _sectionCard(
          title: 'Account',
          children: [
            // User info card
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.electricBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  // Initials avatar
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.electricBlue.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                            color: AppTheme.electricBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(user.email,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Sign out of your Wreniq account',
              color: AppTheme.warning,
              onTap: () => _confirmSignOut(context),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Sign Out?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'You will need to sign in again to use Wreniq.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.chromeAccent)),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }

  // ── Pro ───────────────────────────────────────────────────────────────────────

  Widget _buildProSection(BuildContext context) {
    const gold   = Color(0xFFFFB800);
    const purple = Color(0xFF9C6FFF);
    const green  = Color(0xFF30D158);

    return Consumer<PremiumService>(
      builder: (context, premium, _) => _sectionCard(
        title: 'Wreniq Pro',
        children: [
          // Status tile
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: premium.isPro
                    ? [green.withValues(alpha: 0.12), green.withValues(alpha: 0.06)]
                    : [purple.withValues(alpha: 0.10), AppTheme.electricBlue.withValues(alpha: 0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: premium.isPro
                    ? green.withValues(alpha: 0.35)
                    : purple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: premium.isPro ? green : gold,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        premium.isPro ? 'Wreniq Pro Active' : 'Wreniq Free',
                        style: TextStyle(
                          color: premium.isPro ? green : AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        premium.isPro
                            ? 'All features unlocked (demo mode)'
                            : '${premium.scansRemaining} free scan${premium.scansRemaining == 1 ? '' : 's'} remaining',
                        style: TextStyle(
                          color: premium.isPro
                              ? green.withValues(alpha: 0.7)
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (premium.isPro ? green : purple)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    premium.isPro ? 'PRO' : 'FREE',
                    style: TextStyle(
                      color: premium.isPro ? green : purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Upgrade / manage tile
          if (!premium.isPro)
            _tile(
              icon: Icons.workspace_premium_rounded,
              title: 'Upgrade to Wreniq Pro',
              subtitle: 'Unlimited scans, advanced diagnostics & more',
              color: purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProScreen()),
              ),
            ),

          // Dev toggle
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.chromeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.developer_mode_rounded,
                  color: AppTheme.chromeAccent, size: 20),
            ),
            title: Text(
              premium.isPro ? 'Deactivate Demo Pro' : 'Activate Demo Pro',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
            ),
            subtitle: const Text(
              'For testing only — no real billing',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: Switch(
              value: premium.isPro,
              activeTrackColor: purple,
              onChanged: (_) {
                if (premium.isPro) {
                  premium.deactivateDemoPro();
                } else {
                  premium.activateDemoPro();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle ───────────────────────────────────────────────────────────────────

  Widget _buildVehicleSection(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vp, _) => _sectionCard(
        title: 'Vehicle',
        children: [
          _tile(
            icon: Icons.directions_car_outlined,
            title: vp.hasVehicle ? vp.vehicle!.fullDisplayName : 'No vehicle set up',
            subtitle: vp.hasVehicle ? 'Tap to change' : 'Tap to add your vehicle',
            color: AppTheme.electricBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleSetupScreen()),
            ),
          ),
          if (vp.hasVehicle)
            _tile(
              icon: Icons.delete_outline,
              title: 'Remove Vehicle',
              subtitle: 'Clears saved vehicle data',
              color: AppTheme.warning,
              onTap: () => _confirmRemoveVehicle(context, vp),
            ),
        ],
      ),
    );
  }

  // ── Data ──────────────────────────────────────────────────────────────────────

  Widget _buildDataSection(BuildContext context) {
    return _sectionCard(
      title: 'Data',
      children: [
        Consumer<ScanProvider>(
          builder: (context, sp, _) => _tile(
            icon: Icons.history,
            title: 'Saved Scans',
            subtitle: '${sp.savedScans.length} scan${sp.savedScans.length == 1 ? '' : 's'} stored locally',
            color: const Color(0xFF9C6FFF),
            onTap: null,
          ),
        ),
        _tile(
          icon: Icons.delete_forever_outlined,
          title: 'Clear All Data',
          subtitle: 'Delete all scans and vehicle info',
          color: AppTheme.warning,
          onTap: () => _confirmClearAll(context),
        ),
      ],
    );
  }

  // ── Backend ───────────────────────────────────────────────────────────────────

  Widget _buildBackendSection(BuildContext context) {
    return _sectionCard(
      title: 'AI Backend',
      children: [
        _tile(
          icon: Icons.cloud_outlined,
          title: 'Backend URL',
          subtitle: BackendConfig.baseUrl,
          color: AppTheme.electricBlue,
          onTap: null,
        ),
        _tile(
          icon: Icons.network_check_rounded,
          title: 'Check Connection',
          subtitle: 'Ping the AI backend to verify it is reachable',
          color: AppTheme.success,
          onTap: () => _pingBackend(context),
        ),
      ],
    );
  }

  void _pingBackend(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pinging backend…'),
        duration: Duration(seconds: 3),
      ),
    );
    final (ok, message) = await BackendConfig.checkHealth();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? '✓  $message' : '✗  $message'),
          backgroundColor: ok ? AppTheme.success : AppTheme.warning,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  // ── About ─────────────────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return _sectionCard(
      title: 'About',
      children: [
        _tile(
          icon: Icons.car_repair,
          title: 'Wreniq by Digiscope',
          subtitle: 'AI Automotive Intelligence',
          color: AppTheme.electricBlue,
          onTap: null,
        ),
        _tile(
          icon: Icons.info_outline,
          title: 'Phase 1 MVP',
          subtitle: 'Mock AI — live AI coming in Phase 2',
          color: AppTheme.chromeAccent,
          onTap: null,
        ),
        _tile(
          icon: Icons.shield_outlined,
          title: 'Disclaimer',
          subtitle: 'Always verify part fitment before purchase. Wreniq AI results are estimates only.',
          color: AppTheme.warning,
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildVersion() {
    return Center(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AppTheme.electricBlue, AppTheme.chrome],
            ).createShader(r),
            child: const Text(
              'WRENIQ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('by Digiscope  •  v1.0.0  •  Phase 1 MVP',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: AppTheme.chromeAccent,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, color: AppTheme.chromeAccent, size: 14)
          : null,
    );
  }

  void _confirmRemoveVehicle(BuildContext context, VehicleProvider vp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Remove Vehicle?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will clear your saved vehicle.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.chromeAccent)),
          ),
          TextButton(
            onPressed: () {
              vp.clearVehicle();
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Clear All Data?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will permanently delete all scans and your vehicle.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.chromeAccent)),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearAll();
              if (context.mounted) {
                context.read<VehicleProvider>().clearVehicle();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared.'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }
}
