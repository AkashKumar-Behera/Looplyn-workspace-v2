import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import '../../core/route_transitions.dart';
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

        // Forgot Password Heading
        RichText(
          text: const TextSpan(
            text: 'Forgot ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
            children: [
              TextSpan(
                text: 'password',
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
          'Enter your email to receive recovery instructions',
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

        // Success Message
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      final uri = Uri.parse(_devResetLink!);
                      final token = uri.queryParameters['token'] ?? '';
                      Navigator.of(context).push(
                        SmoothPageRoute(
                          page: ResetPasswordScreen(token: token),
                          direction: SlideDirection.rightToLeft,
                        ),
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
          onSubmitted: (_) => _handleForgotPassword(),
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
              onTap: _isLoading ? null : _handleForgotPassword,
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
                            'Send reset link',
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
        const SizedBox(height: 20),

        // Back to Sign In Link
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.arrowLeft, size: 14, color: Color(0xFF9CA3AF)),
                  SizedBox(width: 6),
                  Text(
                    'Back to Sign in',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
