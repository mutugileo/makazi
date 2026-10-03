import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/root/presentation/screens/root_screen.dart';

class PropMgtApp extends StatelessWidget {
  const PropMgtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EstatePulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RootScreen(),
    );
  }
}
