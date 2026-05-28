import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_background.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

const _kAmber = Color(0xFFFF9500);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool   _showPassword  = false;
  bool   _rememberMe    = true;
  bool   _isLoading     = false;
  String _errorMessage  = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    final error = await context.read<AuthService>().login(
      email:      email,
      password:   password,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  Future<void> _onGoogleTap() async {
    setState(() { _isLoading = true; _errorMessage = ''; });

    final error = await context.read<AuthService>().signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Success — navigate to home.
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (_) => false,
      );
      return;
    }

    if (error == AuthService.googleCancelled) {
      setState(() => _errorMessage = 'Google sign-in cancelled.');
      return;
    }

    setState(() => _errorMessage = error);
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 44),
                  _buildLogo(),
                  const SizedBox(height: 36),
                  _buildWelcomeText(),
                  const SizedBox(height: 28),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 14),
                  _buildRememberForgotRow(),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildErrorCard(),
                  ],
                  const SizedBox(height: 22),
                  _buildSignInButton(),
                  const SizedBox(height: 24),
                  _buildOrDivider(),
                  const SizedBox(height: 24),
                  _buildGoogleButton(),
                  const SizedBox(height: 40),
                  _buildCreateAccountRow(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.electricBlue, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricBlue.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.car_repair,
              size: 38, color: AppTheme.electricBlue),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [AppTheme.electricBlue, AppTheme.chrome],
          ).createShader(r),
          child: const Text(
            'WRENIQ',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'by DIGISCOPE',
          style: TextStyle(
              color: AppTheme.chromeAccent.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 4),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to continue to Wreniq.',
          style: TextStyle(
              color: AppTheme.chromeAccent.withValues(alpha: 0.8),
              fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Email address',
        prefixIcon: const Icon(Icons.email_outlined,
            color: AppTheme.chromeAccent, size: 20),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: !_showPassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outlined,
            color: AppTheme.chromeAccent, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.chromeAccent,
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe
                      ? AppTheme.electricBlue
                      : Colors.transparent,
                  border: Border.all(
                    color: _rememberMe
                        ? AppTheme.electricBlue
                        : AppTheme.chromeAccent.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check,
                        color: Colors.black, size: 13)
                    : null,
              ),
              const SizedBox(width: 9),
              Text('Remember me',
                  style: TextStyle(
                      color: AppTheme.chromeAccent.withValues(alpha: 0.8),
                      fontSize: 13)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen()),
          ),
          child: const Text(
            'Forgot password?',
            style: TextStyle(
                color: AppTheme.electricBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMessage,
                style: const TextStyle(
                    color: AppTheme.warning, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2.5))
            : const Text('SIGN IN', style: TextStyle(letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
              color: AppTheme.chromeAccent.withValues(alpha: 0.25)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
                color: AppTheme.chromeAccent.withValues(alpha: 0.5),
                fontSize: 12,
                letterSpacing: 2),
          ),
        ),
        Expanded(
          child: Divider(
              color: AppTheme.chromeAccent.withValues(alpha: 0.25)),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(
              color: AppTheme.chromeAccent.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _onGoogleTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                  color: Color(0xFF4285F4), shape: BoxShape.circle),
              child: const Center(
                child: Text('G',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Continue with Google',
                style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account? ",
                style: TextStyle(
                    color: AppTheme.chromeAccent.withValues(alpha: 0.7),
                    fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => const SignupScreen(),
                  transitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (_, anim, _, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                    color: AppTheme.electricBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        // Offline demo mode banner — shown when Firebase is unavailable.
        if (context.read<AuthService>().isMockMode) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, color: _kAmber, size: 14),
                SizedBox(width: 8),
                Text(
                  'Running offline — some features unavailable.',
                  style: TextStyle(color: _kAmber, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
