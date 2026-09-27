import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _devResetLink;

  final _api = ApiClient();

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await _api.forgotPassword(email);
      if (res['success'] == true) {
        setState(() {
          _successMessage = 'Password reset instructions dispatched to your email.';
          _devResetLink = res['devResetLink'];
        });
      } else {
        setState(() => _errorMessage = res['error'] ?? 'Request failed');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error']?.toString() ?? 'Connection error. Please try again.';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: isDesktop
          ? Row(
              children: [
                // Left Showcase Panel
                Expanded(
                  flex: 52,
                  child: _buildLeftHeroPanel(),
                ),
                // Right Form Panel
                Expanded(
                  flex: 48,
                  child: _buildRightForgotPanel(),
                ),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/wallpapers/production_studio.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF07070A)),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: const Color(0xE607070A),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildFormCard(isMobile: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLeftHeroPanel() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/wallpapers/production_studio.jpg',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF0C0C12)),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xD9000000),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const LooplynLogo(size: 26),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      text: 'Looplyn',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                      children: [
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: Color(0xFFDC2626), fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              const Text(
                'SECURITY · ACCOUNT RECOVERY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: Color(0xFFA1A1AA),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                text: const TextSpan(
                  text: 'Account\n',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.12,
                    letterSpacing: -1.2,
                  ),
                  children: [
                    TextSpan(
                      text: 'Recovery.',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reset your password securely with an authenticated magic link dispatched directly to your registered inbox.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD4D4D8),
                ),
              ),
              const Spacer(flex: 3),
              const Text(
                '© 2026 Looplyn. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightForgotPanel() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/wallpapers/space_orbit.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF0A0A0F)),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: const Color(0xF209090D),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _buildFormCard(isMobile: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to Sign in
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.arrowLeft, size: 15, color: Color(0xFF9CA3AF)),
                SizedBox(width: 8),
                Text(
                  'Back to Sign in',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        const Text(
          'PASSWORD RESET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: Color(0xFF71717A),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your email address and we will send you a secure password reset link.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E93),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C0B0E),
              borderRadius: BorderRadius.circular(8),
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

        if (_successMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x33064E3B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66059669)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.circleCheck, size: 16, color: Color(0xFF34D399)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (_devResetLink != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27272A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () {
                      final uri = Uri.parse(_devResetLink!);
                      final token = uri.queryParameters['token'] ?? '';
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token)),
                      );
                    },
                    child: const Text('Open Reset Screen (Dev)', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Email Address Input
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Email address',
            hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 14),
            prefixIcon: const Icon(LucideIcons.mail, size: 17, color: Color(0xFF71717A)),
            filled: true,
            fillColor: const Color(0xFF111116),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x14FFFFFF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x14FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
            ),
          ),
          onSubmitted: (_) => _handleForgotPassword(),
        ),
        const SizedBox(height: 24),

        // Red Gradient Submit Button
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEF4444),
                Color(0xFFDC2626),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x52DC2626),
                blurRadius: 18,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isLoading ? null : _handleForgotPassword,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
