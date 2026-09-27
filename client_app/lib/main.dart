import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LooplynApp());
}

class LooplynApp extends StatelessWidget {
  const LooplynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Looplyn Workspace',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
