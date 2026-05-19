import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/engine_component.dart';
import '../services/beginner_mode_service.dart';
import '../services/engine_map_service.dart';
import '../theme/app_theme.dart';

class EngineMapScreen extends StatefulWidget {
  const EngineMapScreen({super.key});

  @override
  State<EngineMapScreen> createState() => _EngineMapScreenState();
}

class _EngineMapScreenState extends State<EngineMapScreen> {
  EngineComponent? _selected;

  void _tap(EngineComponent c) {
    HapticFeedback.lightImpact();
    setState(() => _selected = c);
    _showDetail(c);
  }

  void _showDetail(EngineComponent c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ComponentSheet(component: c),
    ).then((_) => setState(() => _selected = null));
  }

  @override
  Widget build(BuildContext context) {
    final beginner    = context.watch<BeginnerModeService>().enabled;
    final components  = EngineMapService.components;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ENGINE BAY MAP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _BeginnerToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(beginner),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 16),
            _buildMap(context, components),
            const SizedBox(height: 20),
            _buildComponentList(components),
            const SizedBox(height: 16),
            _SafetyNote(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(bool beginner) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: AppTheme.electricBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              beginner
                  ? 'Tap any coloured dot on the map to learn what that part does and what goes wrong with it.'
                  : 'Interactive engine bay schematic. Tap components to view function, failure modes, and maintenance guidance.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _LegendDot(color: const Color(0xFFFF3B30), label: 'High risk'),
        const SizedBox(width: 16),
        _LegendDot(color: const Color(0xFFFFB800), label: 'Medium risk'),
        const SizedBox(width: 16),
        _LegendDot(color: AppTheme.electricBlue,   label: 'Info'),
        const SizedBox(width: 16),
        _LegendDot(color: AppTheme.success,        label: 'Low risk'),
      ],
    );
  }

  Widget _buildMap(BuildContext context, List<EngineComponent> components) {
    return LayoutBuilder(builder: (context, constraints) {
      const mapHeight = 320.0;
      final mapWidth  = constraints.maxWidth;

      return Container(
        width:  mapWidth,
        height: mapHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0D1F33)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.25)),
        ),
        child: Stack(
          children: [
            // Grid lines
            CustomPaint(painter: _GridPainter(), size: Size(mapWidth, mapHeight)),
            // Front label
            const Positioned(
              top: 8, left: 0, right: 0,
              child: Center(child: Text('▲ FRONT', style: TextStyle(color: AppTheme.chromeAccent, fontSize: 10, letterSpacing: 2))),
            ),
            // Rear label
            const Positioned(
              bottom: 8, left: 0, right: 0,
              child: Center(child: Text('▼ REAR / FIREWALL', style: TextStyle(color: AppTheme.chromeAccent, fontSize: 10, letterSpacing: 2))),
            ),
            // Component dots
            ...components.map((c) {
              final x = c.relX * mapWidth  - 18;
              final y = c.relY * mapHeight - 18;
              final isSelected = _selected?.id == c.id;
              return Positioned(
                left: x.clamp(0.0, mapWidth  - 36),
                top:  y.clamp(28.0, mapHeight - 36),
                child: GestureDetector(
                  onTap: () => _tap(c),
                  child: _ComponentDot(component: c, selected: isSelected),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildComponentList(List<EngineComponent> components) {
    final beginner = context.read<BeginnerModeService>().enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALL COMPONENTS',
          style: TextStyle(color: AppTheme.chromeAccent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...components.map((c) => _ComponentListTile(
          component: c,
          beginner:  beginner,
          onTap:     () => _showDetail(c),
        )),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ComponentDot extends StatelessWidget {
  final EngineComponent component;
  final bool selected;
  const _ComponentDot({required this.component, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:  selected ? 22 : 16,
          height: selected ? 22 : 16,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  component.dotColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
            boxShadow: [BoxShadow(color: component.dotColor.withValues(alpha: 0.6), blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          constraints: const BoxConstraints(maxWidth: 70),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            component.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 8, height: 1.2),
          ),
        ),
      ],
    );
  }
}

class _ComponentListTile extends StatelessWidget {
  final EngineComponent component;
  final bool            beginner;
  final VoidCallback    onTap;
  const _ComponentListTile({required this.component, required this.beginner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: component.dotColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: component.dotColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(component.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    beginner ? component.shortDescription : component.shortDescription,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            _RiskBadge(risk: component.failureRisk),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.chromeAccent, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ComponentSheet extends StatelessWidget {
  final EngineComponent component;
  const _ComponentSheet({required this.component});

  @override
  Widget build(BuildContext context) {
    final beginner = context.read<BeginnerModeService>().enabled;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
          Row(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: component.dotColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(component.name,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _RiskBadge(risk: component.failureRisk),
            ],
          ),
          const SizedBox(height: 16),
          _SheetSection(
            title:   beginner ? 'WHAT DOES IT DO?' : 'FUNCTION',
            content: beginner ? component.beginnerExplanation : component.whatItDoes,
          ),
          const SizedBox(height: 12),
          _SheetSection(title: 'COMMON SYMPTOMS', content: null,
            child: Column(
              children: component.symptoms.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: component.dotColor.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                ]),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _SheetSection(
            title:   beginner ? 'MAINTENANCE TIP' : 'MAINTENANCE',
            content: component.maintenanceTip,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Always consult a qualified mechanic before attempting repairs. Incorrect repairs can be dangerous.',
              style: TextStyle(color: Color(0xFFFFB800), fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String  title;
  final String? content;
  final Widget? child;
  const _SheetSection({required this.title, required this.content, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.electricBlue, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (content != null)
            Text(content!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5))
          else
            child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String risk;
  const _RiskBadge({required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = risk == 'High'
        ? const Color(0xFFFF3B30)
        : risk == 'Medium'
            ? const Color(0xFFFFB800)
            : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$risk risk', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
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
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.shield_outlined, color: Color(0xFFFFB800), size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Component information is general and may not apply to all vehicles. AI may be incorrect. Always verify repairs with a qualified mechanic.',
            style: TextStyle(color: Color(0xFFFFB800), fontSize: 11, height: 1.4),
          ),
        ),
      ]),
    );
  }
}

// ── Custom grid painter ───────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00B4FF).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
