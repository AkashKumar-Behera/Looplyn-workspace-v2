import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import 'forgot_password_screen.dart';
import '../studio/studio_calendar_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _api = ApiClient();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.login(email, password);
      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudioCalendarScreen()),
        );
      } else {
        setState(() => _errorMessage = res['error'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error']?.toString() ?? 'Unable to connect to server. Check connection.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    if (!isDesktop) {
      // Mobile / Tablet: Clean pure dark canvas, no bg image, native feel
      return Scaffold(
        backgroundColor: const Color(0xFF09090C),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildFormContent(isMobile: true),
              ),
            ),
          ),
        ),
      );
    }

    // Desktop: Authentic Wallpaper + Dark Vignette + Frosted Glass Card on Right
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Background Image
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (ctx, err, stack) => Container(color: Colors.black),
          ),

          // 2. Dark Mood Vignette Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),

          // 3. Desktop Frosted Glass Form Card
          Positioned(
            right: size.width * 0.10,
            top: size.height * 0.14,
            bottom: size.height * 0.10,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 38.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0C10).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: _buildFormContent(isMobile: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent({bool isMobile = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Logo Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const LooplynLogo(size: 34),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                text: 'Looplyn',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
                children: [
                  TextSpan(
                    text: '▪',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Design agency in Bhubaneswar, Odisha',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 32),

        // Welcome back Heading
        RichText(
          text: const TextSpan(
            text: 'Welcome ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
            children: [
              TextSpan(
                text: 'back',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to your workspace',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF71717A),
          ),
        ),
        const SizedBox(height: 26),

        // Error Message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C0B0E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x66DC2626)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Email Label & Input
        const Text(
          'Email',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF71717A)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'you@looplyn.tech',
            hintStyle: const TextStyle(color: Color(0xFF3F3F46), fontSize: 13),
            prefixIcon: const Icon(LucideIcons.mail, size: 16, color: Color(0xFF71717A)),
            filled: true,
            fillColor: const Color(0xFF0F0F12).withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Label & Input
        const Text(
          'Password',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF71717A)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFF3F3F46), fontSize: 13),
            prefixIcon: const Icon(LucideIcons.lock, size: 16, color: Color(0xFF71717A)),
            filled: true,
            fillColor: const Color(0xFF0F0F12).withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 16,
                color: const Color(0xFF71717A),
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 10),

        // Forgot password Link
        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Dark Crimson Red Pill Button
        Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFC0151C), // Rich crimson red
                Color(0xFF6B0E14), // Dark deep wine
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC0151C).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _isLoading ? null : _handleLogin,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            LucideIcons.arrowRight,
                            color: Colors.white,
                            size: 15,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
