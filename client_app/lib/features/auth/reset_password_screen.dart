import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isValidatingToken = true;
  String? _errorMessage;
  String? _successMessage;
  String? _userName;

  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      final res = await _api.verifyResetToken(widget.token);
      if (res['success'] == true) {
        setState(() {
          _userName = res['name'];
          _isValidatingToken = false;
        });
      } else {
        setState(() {
          _errorMessage = res['error'] ?? 'Invalid or expired token';
          _isValidatingToken = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid or expired token';
        _isValidatingToken = false;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.resetPassword(widget.token, password);
      if (res['success'] == true) {
        setState(() {
          _successMessage = 'Password changed successfully! Redirecting to sign in...';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() => _errorMessage = res['error'] ?? 'Failed to reset password');
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
    if (_isValidatingToken) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 36, color: AppTheme.success),
                  const SizedBox(height: 16),
                  const Text(
                    'Create New Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  if (_userName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Welcome $_userName, set your new password below.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: Text(_successMessage!, style: const TextStyle(color: AppTheme.success, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Minimum 6 characters',
                      prefixIcon: const Icon(LucideIcons.lock, size: 18, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppTheme.textMuted),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Confirm New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      hintText: 'Re-enter new password',
                      prefixIcon: Icon(LucideIcons.lock, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Update Password & Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
