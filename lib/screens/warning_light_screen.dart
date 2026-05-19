import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/warning_light.dart';
import '../services/beginner_mode_service.dart';
import '../services/warning_light_service.dart';
import '../theme/app_theme.dart';

class WarningLightScreen extends StatefulWidget {
  const WarningLightScreen({super.key});

  @override
  State<WarningLightScreen> createState() => _WarningLightScreenState();
}

class _WarningLightScreenState extends State<WarningLightScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories => ['All', ...WarningLightService.categories];

  List<WarningLight> get _filtered {
    if (_selectedCategory == 'All') return WarningLightService.all;
    return WarningLightService.byCategory(_selectedCategory);
  }

  void _showDetail(WarningLight light) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LightDetailSheet(light: light),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beginner = context.watch<BeginnerModeService>().enabled;
    final lights   = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WARNING LIGHT SCANNER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8), child: _BeginnerToggle()),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(beginner),
          _buildCategoryBar(),
          Expanded(child: _buildGrid(lights, beginner)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool beginner) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppTheme.electricBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              beginner
                  ? 'See a light on your dashboard you don\'t recognise? Find it here to learn what it means.'
                  : 'Identify dashboard warning lights. Tap any indicator to view severity, meaning, and recommended action.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat      = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.electricBlue.withValues(alpha: 0.15)
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppTheme.electricBlue.withValues(alpha: 0.6)
                      : AppTheme.chromeAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? AppTheme.electricBlue : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<WarningLight> lights, bool beginner) {
    if (lights.isEmpty) {
      return const Center(
        child: Text('No lights in this category', style: TextStyle(color: AppTheme.chromeAccent, fontSize: 14)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:    2,
        mainAxisSpacing:   10,
        crossAxisSpacing:  10,
        childAspectRatio:  1.1,
      ),
      itemCount: lights.length,
      itemBuilder: (_, i) => _LightCard(
        light:    lights[i],
        beginner: beginner,
        onTap:    () => _showDetail(lights[i]),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LightCard extends StatelessWidget {
  final WarningLight light;
  final bool         beginner;
  final VoidCallback onTap;
  const _LightCard({required this.light, required this.beginner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: light.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: light.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(light.icon, color: light.color, size: 20),
                ),
                const Spacer(),
                _SeverityDot(severity: light.severity),
              ],
            ),
            const Spacer(),
            Text(
              light.name,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  light.safeToRide ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 12,
                  color: light.safeToRide ? AppTheme.success : const Color(0xFFFF3B30),
                ),
                const SizedBox(width: 4),
                Text(
                  light.safeToRide ? 'OK to drive' : 'Stop driving',
                  style: TextStyle(
                    color: light.safeToRide ? AppTheme.success : const Color(0xFFFF3B30),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LightDetailSheet extends StatelessWidget {
  final WarningLight light;
  const _LightDetailSheet({required this.light});

  @override
  Widget build(BuildContext context) {
    final beginner = context.read<BeginnerModeService>().enabled;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.chromeAccent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: light.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(light.icon, color: light.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(light.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _SeverityDot(severity: light.severity, showLabel: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Safe to drive
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (light.safeToRide ? AppTheme.success : const Color(0xFFFF3B30)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (light.safeToRide ? AppTheme.success : const Color(0xFFFF3B30)).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  light.safeToRide ? Icons.check_circle : Icons.dangerous,
                  color: light.safeToRide ? AppTheme.success : const Color(0xFFFF3B30),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SAFE TO DRIVE?',
                          style: TextStyle(color: AppTheme.chromeAccent, fontSize: 10, letterSpacing: 1.5)),
                      const SizedBox(height: 2),
                      Text(
                        light.safeToRide ? 'Yes — but get it checked soon' : 'NO — stop driving immediately',
                        style: TextStyle(
                          color: light.safeToRide ? AppTheme.success : const Color(0xFFFF3B30),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // What it means
          _InfoCard(
            title:   beginner ? 'WHAT DOES THIS MEAN?' : 'MEANING',
            content: beginner ? light.beginnerExplanation : light.whatItMeans,
            color:   AppTheme.electricBlue,
          ),
          const SizedBox(height: 10),
          // What to do
          _InfoCard(
            title:   beginner ? 'WHAT SHOULD I DO?' : 'RECOMMENDED ACTION',
            content: light.whatToDo,
            color:   const Color(0xFFFFB800),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.chromeAccent.withValues(alpha: 0.15)),
            ),
            child: const Text(
              'DISCLAIMER: Information is general guidance only and may not apply to all vehicles. Always consult a qualified mechanic for diagnosis and repair.',
              style: TextStyle(color: AppTheme.chromeAccent, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final Color  color;
  const _InfoCard({required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _SeverityDot extends StatelessWidget {
  final String severity;
  final bool   showLabel;
  const _SeverityDot({required this.severity, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final color = severity == 'Critical'
        ? const Color(0xFFFF3B30)
        : severity == 'Warning'
            ? const Color(0xFFFFB800)
            : AppTheme.electricBlue;

    if (!showLabel) {
      return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(severity, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
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
          color: svc.enabled ? AppTheme.electricBlue.withValues(alpha: 0.15) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: svc.enabled ? AppTheme.electricBlue.withValues(alpha: 0.6) : AppTheme.chromeAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school_outlined, size: 14, color: svc.enabled ? AppTheme.electricBlue : AppTheme.chromeAccent),
          const SizedBox(width: 4),
          Text('Beginner', style: TextStyle(fontSize: 11, color: svc.enabled ? AppTheme.electricBlue : AppTheme.chromeAccent)),
        ]),
      ),
    );
  }
}
