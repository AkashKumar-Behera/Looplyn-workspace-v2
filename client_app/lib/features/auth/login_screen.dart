import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import '../../core/route_transitions.dart';
import 'reset_password_screen.dart';
import '../studio/studio_calendar_screen.dart';
import '../admin/super_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Mode: true = Forgot Password, false = Login
  bool _isForgotPassword = false;

  // Login Controllers & States
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Forgot Password Controllers & States
  final _forgotEmailController = TextEditingController();
  bool _isForgotLoading = false;
  String? _forgotErrorMessage;
  String? _forgotSuccessMessage;
  String? _devResetLink;

  // Entrance Animation
  late final AnimationController _cardAnimController;
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;

  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _cardFadeAnim = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOutCubic,
    );

    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimController.forward();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

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
        final user = res['user'];
        final role = user != null ? user['role']?.toString() : null;
        if (role == 'super_admin') {
          Navigator.of(context).pushReplacement(
            SmoothPageRoute(
              page: const SuperAdminScreen(),
              direction: SlideDirection.fadeOnly,
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            SmoothPageRoute(
              page: const StudioCalendarScreen(),
              direction: SlideDirection.fadeOnly,
            ),
          );
        }
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

  Future<void> _handleForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty) {
      setState(() => _forgotErrorMessage = 'Please enter your email address');
      return;
    }

    setState(() {
      _isForgotLoading = true;
      _forgotErrorMessage = null;
      _forgotSuccessMessage = null;
    });

    try {
      final res = await _api.forgotPassword(email);
      if (res['success'] == true) {
        setState(() {
          _forgotSuccessMessage = 'Password reset instructions dispatched to your email.';
          _devResetLink = res['devResetLink'];
        });
      } else {
        setState(() => _forgotErrorMessage = res['error'] ?? 'Request failed');
      }
    } on DioException catch (e) {
      setState(() {
        _forgotErrorMessage = e.response?.data?['error']?.toString() ?? 'Connection error. Please try again.';
      });
    } catch (e) {
      setState(() {
        _forgotErrorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isForgotLoading = false);
    }
  }

  void _switchToForgotPassword() {
    setState(() {
      _isForgotPassword = true;
      _forgotErrorMessage = null;
      _forgotSuccessMessage = null;
      if (_emailController.text.isNotEmpty && _forgotEmailController.text.isEmpty) {
        _forgotEmailController.text = _emailController.text;
      }
    });
  }

  void _switchToLogin() {
    setState(() {
      _isForgotPassword = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    if (!isDesktop) {
      // Mobile / Tablet: Clean pure dark canvas, no bg image, animated card
      return Scaffold(
        backgroundColor: const Color(0xFF09090C),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _cardFadeAnim,
                  child: SlideTransition(
                    position: _cardSlideAnim,
                    child: _buildAnimatedCardContent(isMobile: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Desktop: Authentic Wallpaper + Dark Vignette + Animated Frosted Glass Card
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

          // 3. Desktop Frosted Glass Form Card with Butter-Smooth Entrance & In-Card Transitions
          Positioned(
            right: size.width * 0.10,
            top: size.height * 0.12,
            bottom: size.height * 0.08,
            child: Center(
              child: FadeTransition(
                opacity: _cardFadeAnim,
                child: SlideTransition(
                  position: _cardSlideAnim,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: 430,
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
                          child: _buildAnimatedCardContent(isMobile: false),
                        ),
                      ),
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

  Widget _buildAnimatedCardContent({required bool isMobile}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final isLogin = child.key == const ValueKey('login_view');
        final inOffset = isLogin ? const Offset(-0.14, 0.0) : const Offset(0.14, 0.0);

        return SlideTransition(
          position: Tween<Offset>(begin: inOffset, end: Offset.zero).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _isForgotPassword
          ? _buildForgotPasswordForm(key: const ValueKey('forgot_view'), isMobile: isMobile)
          : _buildLoginForm(key: const ValueKey('login_view'), isMobile: isMobile),
    );
  }

  // -------------------------------------------------------------
  // 1. Sign In Form
  // -------------------------------------------------------------
  Widget _buildLoginForm({required Key key, required bool isMobile}) {
    return Column(
      key: key,
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

        // Credentials Autofill Group
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email Label & Input
              const Text(
                'Email',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                textInputAction: TextInputAction.next,
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
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
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
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Forgot password Link (Smooth In-Card Switch)
        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _switchToForgotPassword,
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

        // Crimson Red Gradient Pill Button
        Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFC0151C),
                Color(0xFF6B0E14),
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

  // -------------------------------------------------------------
  // 2. Forgot Password Form
  // -------------------------------------------------------------
  Widget _buildForgotPasswordForm({required Key key, required bool isMobile}) {
    return Column(
      key: key,
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
        if (_forgotErrorMessage != null) ...[
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
                    _forgotErrorMessage!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Success Message
        if (_forgotSuccessMessage != null) ...[
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
                        _forgotSuccessMessage!,
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
          controller: _forgotEmailController,
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

        // Crimson Red Gradient Pill Button
        Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFC0151C),
                Color(0xFF6B0E14),
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
              onTap: _isForgotLoading ? null : _handleForgotPassword,
              child: Center(
                child: _isForgotLoading
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

        // Back to Sign In Link (Smooth Reverse Slide)
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _switchToLogin,
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
