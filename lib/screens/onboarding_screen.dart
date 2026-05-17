import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

const String _kOnboardingDone = 'wreniq_onboarding_done';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.document_scanner_outlined,
      iconColor: AppTheme.electricBlue,
      title: 'AI Part Scanner',
      body: 'Point your camera at any car part or dashboard warning light '
          'and get an instant AI-powered diagnosis.',
    ),
    _Slide(
      icon: Icons.build_circle_outlined,
      iconColor: Color(0xFF00E676),
      title: 'Step-by-Step DIY Guide',
      body: 'Interactive repair guides with tool checklists, torque specs, '
          'and safety warnings — built for the garage, not the workshop.',
    ),
    _Slide(
      icon: Icons.savings_outlined,
      iconColor: Color(0xFFFF9500),
      title: 'Savings Tracker',
      body: 'Every repair you complete yourself is logged. See exactly how '
          'much you\'ve saved compared to dealership prices.',
    ),
    _Slide(
      icon: Icons.monitor_heart_outlined,
      iconColor: Color(0xFFBF5AF2),
      title: 'Vehicle Health Score',
      body: 'Your car\'s condition at a glance. Track diagnostics, '
          'maintenance history, and get smart alerts before problems escalate.',
    ),
  ];

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthGate(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _slides.length - 1) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _finish();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: isLast
                    ? const SizedBox(height: 36)
                    : TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                              color: AppTheme.chromeAccent, fontSize: 14),
                        ),
                      ),
              ),
            ),

            // Page slides
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _page = i);
                },
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                children: [
                  _DotRow(count: _slides.length, current: _page),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_page].iconColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5),
                      ),
                      child: Text(isLast ? 'Get Started' : 'Next'),
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'I\'ll explore on my own',
                        style: TextStyle(
                            color: AppTheme.chromeAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

// ── Single slide page ─────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle with glow
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.iconColor.withValues(alpha: 0.08),
              border: Border.all(
                  color: slide.iconColor.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: slide.iconColor.withValues(alpha: 0.25),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(slide.icon, size: 64, color: slide.iconColor),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Safety notice on last slide
        ],
      ),
    );
  }
}

// ── Dot indicator row ─────────────────────────────────────────────────────────

class _DotRow extends StatelessWidget {
  final int count;
  final int current;
  const _DotRow({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.electricBlue
                : AppTheme.chromeAccent.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
