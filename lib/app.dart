import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/screens/app_shell_screen.dart';

class PropMgtApp extends StatelessWidget {
  const PropMgtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PropMgtApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AppShellScreen(),
    );
  }
}
