import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_gate.dart';

class PropMgtApp extends StatelessWidget {
  const PropMgtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makazi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
