import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Animated dual-glow background used across all auth screens.
class AuthBackground extends StatefulWidget {
  const AuthBackground({super.key});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.10, end: 0.26).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Stack(
        children: [
          // Top-left electric blue glow
          Positioned(
            top: -90, left: -90,
            child: _blob(320, AppTheme.electricBlue, _anim.value),
          ),
          // Bottom-right purple glow
          Positioned(
            bottom: -70, right: -70,
            child: _blob(260, const Color(0xFF9C6FFF), _anim.value * 0.65),
          ),
          // Subtle mid-page teal hint
          Positioned(
            top: 260, right: -120,
            child: _blob(200, const Color(0xFF00D4AA), _anim.value * 0.25),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
        ),
      );
}
