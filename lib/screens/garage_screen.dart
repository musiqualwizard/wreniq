import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_vehicle_screen.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY GARAGE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Add vehicle',
            icon: const Icon(Icons.add, color: AppTheme.electricBlue),
            onPressed: () => _openAddScreen(context),
          ),
        ],
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, vp, _) {
          if (vp.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.electricBlue),
            );
          }
          if (vp.vehicles.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildList(context, vp);
        },
      ),
    );
  }

  // ── Screens ────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.electricBlue.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.garage_outlined,
                  size: 52, color: AppTheme.electricBlue),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Garage is Empty',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your vehicles to get accurate\npart identification and repair guides.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _openAddScreen(context),
              icon: const Icon(Icons.add),
              label: const Text('ADD FIRST VEHICLE'),
            ),
            const SizedBox(height: 32),
            _disclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, VehicleProvider vp) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...vp.vehicles.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _VehicleCard(
              vehicle:   v,
              onEdit:    () => _openEditScreen(context, v),
              onDelete:  () => _confirmDelete(context, vp, v),
              onPrimary: () => vp.setPrimary(v.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _disclaimer(),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _openAddScreen(context),
            icon: const Icon(Icons.add, size: 17, color: AppTheme.electricBlue),
            label: const Text(
              'ADD ANOTHER VEHICLE',
              style: TextStyle(color: AppTheme.electricBlue, fontSize: 12, letterSpacing: 1),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppTheme.electricBlue.withValues(alpha: 0.4), width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openAddScreen(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()),
    );
  }

  Future<void> _openEditScreen(BuildContext context, Vehicle v) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditVehicleScreen(vehicle: v)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, VehicleProvider vp, Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Vehicle',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove ${v.nicknameOrDefault} from your Garage?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.chromeAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vp.deleteVehicle(v.id);
    }
  }

  // ── Shared widget ──────────────────────────────────────────────────────────

  Widget _disclaimer() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppTheme.chromeAccent, size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'VIN data is provided by NHTSA and may be incomplete. '
                'Always verify vehicle details before purchasing parts.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ),
      );
}

// ── Vehicle card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrimary;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = vehicle.isPrimary;
    final borderColor = isPrimary
        ? AppTheme.electricBlue.withValues(alpha: 0.5)
        : AppTheme.chromeAccent.withValues(alpha: 0.15);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isPrimary ? 1.5 : 1.0),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                    color: AppTheme.electricBlue.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 2),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top strip ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppTheme.electricBlue.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: isPrimary
                      ? AppTheme.electricBlue
                      : AppTheme.chromeAccent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vehicle.nicknameOrDefault,
                    style: TextStyle(
                      color: isPrimary
                          ? AppTheme.electricBlue
                          : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.electricBlue.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppTheme.electricBlue, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'PRIMARY',
                          style: TextStyle(
                              color: AppTheme.electricBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Details ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                if (vehicle.trim.isNotEmpty || vehicle.engine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (vehicle.trim.isNotEmpty) vehicle.trim,
                      if (vehicle.engine.isNotEmpty) vehicle.engine,
                    ].join('  •  '),
                    style: const TextStyle(
                        color: AppTheme.chromeAccent, fontSize: 13),
                  ),
                ],
                if (vehicle.vin.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_outlined,
                          color: AppTheme.chromeAccent, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        vehicle.vin,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2A2A3E)),

          // ── Action row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (!isPrimary)
                  _cardButton(
                    icon: Icons.star_outline,
                    label: 'Set Primary',
                    color: AppTheme.electricBlue,
                    onTap: onPrimary,
                  ),
                if (!isPrimary) const SizedBox(width: 4),
                _cardButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppTheme.chromeAccent,
                  onTap: onEdit,
                ),
                const Spacer(),
                _cardButton(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  color: AppTheme.warning,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
