import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/admin/super_admin_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/client/client_review_screen.dart';
import 'features/layout/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  runApp(const LooplynApp());
}

class LooplynApp extends StatelessWidget {
  const LooplynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Looplyn Workspace',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeController.instance.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _api = ApiClient();
  bool _isChecking = true;
  Widget _targetScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final token = await _api.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isChecking = false);
        return;
      }

      final res = await _api.getMe();
      if (res['success'] == true && res['user'] != null) {
        final role = res['user']['role']?.toString();
        if (role == 'super_admin') {
          _targetScreen = const SuperAdminScreen();
        } else if (role == 'client') {
          _targetScreen = const ClientReviewScreen();
        } else {
          _targetScreen = const AppShell();
        }
      }
    } catch (_) {
      _targetScreen = const LoginScreen();
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      final isDark = ThemeController.instance.isDark;
      return Scaffold(
        backgroundColor: AppColors.bg(isDark),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentRed),
        ),
      );
    }
    return _targetScreen;
  }
}
