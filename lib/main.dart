import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/data/secure_session_storage.dart';
import 'features/auth/data/restore_device_session.dart';
import 'features/auth/presentation/state/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    // No silent fallback to the demo: if this fails the app says so.
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(),
        ),
      );
    } catch (error) {
      runApp(_StartupError(error: error));
      return;
    }
  }

  final restoredDevice = await restoreDeviceSession();

  runApp(
    ProviderScope(
      overrides: [restoredDeviceProvider.overrideWithValue(restoredDevice)],
      child: const PropMgtApp(),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Makazi could not start. Close the app and open it again.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
