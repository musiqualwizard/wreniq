import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../providers/scan_provider.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';
import 'garage_screen.dart';
import 'pro_screen.dart';
import 'results_screen.dart';
import 'vehicle_setup_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  XFile?   _pickedImage;
  Vehicle? _selectedVehicle; // null until didChangeDependencies runs
  final _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialise once — don't override a deliberate user selection on rebuilds
    _selectedVehicle ??= context.read<VehicleProvider>().primaryVehicle;
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _analyze() async {
    if (_pickedImage == null) return;

    final premium = context.read<PremiumService>();
    if (!premium.canScan) {
      _showUpgradeSheet();
      return;
    }

    await premium.incrementScanCount();
    if (!mounted) return;

    final sp = context.read<ScanProvider>();
    final v  = _selectedVehicle ?? context.read<VehicleProvider>().primaryVehicle;

    await sp.analyzePart(
      imagePath: _pickedImage!.path,
      year:  v?.year  ?? 'Unknown',
      make:  v?.make  ?? 'Unknown',
      model: v?.model ?? 'Unknown',
      trim:  v?.trim  ?? 'Unknown',
    );

    if (!mounted) return;

    if (sp.state == ScanState.done) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    } else if (sp.state == ScanState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sp.errorMessage),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  void _showUpgradeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UpgradeSheet(
        onGoProTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProScreen()),
          );
        },
      ),
    );
  }

  // Open bottom sheet to pick a vehicle from the garage
  Future<void> _showVehiclePicker(
      BuildContext context, List<Vehicle> vehicles) async {
    final picked = await showModalBottomSheet<Vehicle>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VehiclePickerSheet(
        vehicles:        vehicles,
        selectedVehicle: _selectedVehicle,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedVehicle = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp        = context.watch<VehicleProvider>();
    final isScanning = context.watch<ScanProvider>().state == ScanState.scanning;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('SCAN PART'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: isScanning ? null : () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle selector — shows garage picker when vehicles exist,
                // or the old "add vehicle" warning when the garage is empty
                if (!vp.hasVehicle)
                  _vehicleWarningBanner(context)
                else
                  _vehicleSelectorRow(context, vp.vehicles, isScanning),
                const Text(
                  'Photo of Part',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take a clear, well-lit photo of the part you want to identify.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildImagePreview(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _sourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: isScanning ? null : () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sourceButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: isScanning ? null : () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_pickedImage != null && !isScanning) ? _analyze : null,
                    icon: const Icon(Icons.search),
                    label: const Text('ANALYZE PART'),
                  ),
                ),
                const SizedBox(height: 10),
                _buildScanLimitBadge(context),
                const SizedBox(height: 20),
                _buildTips(),
              ],
            ),
          ),
        ),

        // Full-screen overlay while AI analysis runs
        if (isScanning)
          Container(
            color: Colors.black.withValues(alpha: 0.75),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.electricBlue.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricBlue.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            color: AppTheme.electricBlue,
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Connecting to Wreniq AI…',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Identifying your part…',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScanLimitBadge(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premium, _) {
        if (premium.isPro) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.all_inclusive_rounded,
                  color: Color(0xFF9C6FFF), size: 14),
              const SizedBox(width: 5),
              const Text('Unlimited scans — Wreniq Pro',
                  style: TextStyle(
                      color: Color(0xFF9C6FFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          );
        }
        final remaining = premium.scansRemaining;
        final color = remaining <= 1 ? AppTheme.warning : AppTheme.chromeAccent;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              '$remaining free scan${remaining == 1 ? '' : 's'} remaining',
              style: TextStyle(color: color, fontSize: 12),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProScreen()),
              ),
              child: const Text(
                'Go Pro',
                style: TextStyle(
                    color: Color(0xFF9C6FFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF9C6FFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  // Compact selector shown when the garage has at least one vehicle
  Widget _vehicleSelectorRow(
      BuildContext context, List<Vehicle> vehicles, bool isScanning) {
    final v = _selectedVehicle ?? vehicles.first;
    return GestureDetector(
      onTap: isScanning ? null : () => _showVehiclePicker(context, vehicles),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.electricBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car,
                color: AppTheme.electricBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SCANNING FOR',
                    style: TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v.nicknameOrDefault,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  if (v.trim.isNotEmpty)
                    Text(
                      v.trim,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (!isScanning) ...[
              const Text(
                'CHANGE',
                style: TextStyle(
                    color: AppTheme.chromeAccent,
                    fontSize: 11,
                    letterSpacing: 1),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more,
                  color: AppTheme.chromeAccent, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vehicleWarningBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VehicleSetupScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No vehicle set up — results may be less accurate. Tap to add your vehicle.',
                style: TextStyle(color: AppTheme.warning, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_pickedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_pickedImage!.path),
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 52,
              color: AppTheme.electricBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text('Tap to select a photo',
                style: TextStyle(color: AppTheme.chromeAccent, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('or use the buttons below',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: onTap == null ? 0.08 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: onTap == null
                    ? AppTheme.chromeAccent
                    : AppTheme.electricBlue,
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: onTap == null
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
    const tips = [
      'Ensure the part is in focus and well-lit',
      'Remove dirt or grease for better accuracy',
      'Include any visible part numbers if possible',
      'Multiple angles can improve identification',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.electricBlue, size: 18),
              SizedBox(width: 8),
              Text('TIPS FOR BEST RESULTS',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(color: AppTheme.electricBlue)),
                  Expanded(
                    child: Text(tip,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upgrade bottom sheet ──────────────────────────────────────────────────────

class _UpgradeSheet extends StatelessWidget {
  final VoidCallback onGoProTap;

  const _UpgradeSheet({required this.onGoProTap});

  static const _purple = Color(0xFF9C6FFF);
  static const _gold   = Color(0xFFFFB800);
  static const _teal   = Color(0xFF00D4AA);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.chromeAccent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: _gold, size: 32),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'Scan Limit Reached',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve used all ${PremiumService.freeScanLimit} free scans.\n'
              'Upgrade to Wreniq Pro for unlimited access.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Key benefits
            _benefit(Icons.all_inclusive_rounded, 'Unlimited AI Part Scans'),
            const SizedBox(height: 8),
            _benefit(Icons.electrical_services,   'Advanced OBD2 Diagnostics'),
            const SizedBox(height: 8),
            _benefit(Icons.calculate_outlined,    'Repair Cost Estimator'),
            const SizedBox(height: 24),
            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  elevation: 0,
                ),
                onPressed: onGoProTap,
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text('UPGRADE TO PRO'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later',
                  style: TextStyle(color: AppTheme.chromeAccent, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: _teal, size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 13)),
      ],
    );
  }
}

// ── Vehicle picker bottom sheet ───────────────────────────────────────────────

class _VehiclePickerSheet extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle?      selectedVehicle;

  const _VehiclePickerSheet({
    required this.vehicles,
    required this.selectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.chromeAccent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.directions_car,
                    color: AppTheme.electricBlue, size: 18),
                SizedBox(width: 8),
                Text(
                  'CHOOSE VEHICLE',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...vehicles.map((v) {
            final isSelected = v.id == selectedVehicle?.id;
            return InkWell(
              onTap: () => Navigator.pop(context, v),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.electricBlue
                              : AppTheme.chromeAccent.withValues(alpha: 0.4),
                          width: isSelected ? 2 : 1.5,
                        ),
                        color: isSelected
                            ? AppTheme.electricBlue
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.black, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.nicknameOrDefault,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.electricBlue
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (v.trim.isNotEmpty)
                            Text(v.trim,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                    if (v.isPrimary)
                      const Text(
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
            );
          }),
          const Divider(height: 1, color: Color(0xFF2A2A3E)),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GarageScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.garage_outlined,
                      color: AppTheme.chromeAccent, size: 18),
                  SizedBox(width: 14),
                  Text(
                    'Manage Garage',
                    style: TextStyle(
                        color: AppTheme.chromeAccent, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
