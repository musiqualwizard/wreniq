import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/beginner_mode_service.dart';
import '../services/visual_id_service.dart';
import '../theme/app_theme.dart';
import 'part_detail_screen.dart';

class VisualIdScreen extends StatefulWidget {
  const VisualIdScreen({super.key});

  @override
  State<VisualIdScreen> createState() => _VisualIdScreenState();
}

class _VisualIdScreenState extends State<VisualIdScreen> {
  XFile? _image;
  bool   _loading = false;
  String? _error;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    HapticFeedback.lightImpact();
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file != null) setState(() { _image = file; _error = null; });
  }

  Future<void> _identify() async {
    if (_image == null) return;
    HapticFeedback.mediumImpact();

    setState(() { _loading = true; _error = null; });

    try {
      final vp = context.read<VehicleProvider>();
      final v  = vp.primaryVehicle;
      final result = await VisualIdService.identify(
        imagePath: _image!.path,
        year:  v?.year  ?? 'Unknown',
        make:  v?.make  ?? 'Unknown',
        model: v?.model ?? 'Unknown',
        trim:  v?.trim  ?? 'Unknown',
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartDetailScreen(result: result)),
      );
    } catch (e) {
      setState(() => _error = 'Identification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final beginner = context.watch<BeginnerModeService>().enabled;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('WHAT IS THIS?'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: _loading ? null : () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _BeginnerToggle(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoBanner(beginner: beginner),
                const SizedBox(height: 20),
                _buildImageArea(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _srcBtn(Icons.photo_library_outlined, 'Gallery',   () => _pick(ImageSource.gallery))),
                    const SizedBox(width: 12),
                    Expanded(child: _srcBtn(Icons.camera_alt_outlined,    'Camera',    () => _pick(ImageSource.camera))),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_image != null && !_loading) ? _identify : null,
                    icon: const Icon(Icons.search),
                    label: const Text('IDENTIFY PART'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 24),
                _buildTips(beginner),
                const SizedBox(height: 16),
                _SafetyNote(),
              ],
            ),
          ),
        ),
        if (_loading) _LoadingOverlay(),
      ],
    );
  }

  Widget _buildImageArea() {
    if (_image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(_image!.path),
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _image = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => _pick(ImageSource.gallery),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 56, color: AppTheme.electricBlue.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Tap to select a photo',
                style: TextStyle(color: AppTheme.chromeAccent, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Point at the part and use Camera below',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _srcBtn(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.electricBlue, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTips(bool beginner) {
    final tips = beginner
        ? ['Take the photo in good light', 'Get close enough to fill the frame', 'Clean the part if it\'s very dirty']
        : ['Ensure part is in focus and well-lit', 'Include visible part numbers if present', 'Remove obstructions for cleaner identification'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lightbulb_outline, color: AppTheme.electricBlue, size: 16),
            SizedBox(width: 8),
            Text('TIPS', style: TextStyle(color: AppTheme.electricBlue, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: AppTheme.electricBlue)),
                Expanded(child: Text(t, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final bool beginner;
  const _InfoBanner({required this.beginner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.electricBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              beginner
                  ? 'Take a photo of any car part and we\'ll tell you what it is, what it does, and if it\'s a problem.'
                  : 'Point and capture any automotive component. AI will identify the part and provide comprehensive diagnostic information.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppTheme.warning, fontSize: 13))),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFFFFB800), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI identification may be incorrect. Always verify with a qualified mechanic before making repairs. Dangerous repairs require professional service.',
              style: TextStyle(color: Color(0xFFFFB800), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeginnerToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BeginnerModeService>();
    return GestureDetector(
      onTap: svc.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: svc.enabled
              ? AppTheme.electricBlue.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: svc.enabled
                ? AppTheme.electricBlue.withValues(alpha: 0.6)
                : AppTheme.chromeAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 14,
                color: svc.enabled ? AppTheme.electricBlue : AppTheme.chromeAccent),
            const SizedBox(width: 4),
            Text(
              'Beginner',
              style: TextStyle(
                fontSize: 11,
                color: svc.enabled ? AppTheme.electricBlue : AppTheme.chromeAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: AppTheme.electricBlue.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 52, height: 52,
                child: CircularProgressIndicator(color: AppTheme.electricBlue, strokeWidth: 3)),
              SizedBox(height: 20),
              Text('Identifying part…',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Wreniq AI is analysing your photo',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
