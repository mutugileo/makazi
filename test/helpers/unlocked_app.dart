import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prop_mgt_app/app.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';

/// The app with the tenant already signed in and unlocked, for tests that
/// are about the screens behind the sign-in.
ProviderScope unlockedApp() => ProviderScope(
  overrides: [
    authProvider.overrideWith(
      () => AuthNotifier(initialStage: AuthStage.unlocked),
    ),
  ],
  child: const PropMgtApp(),
);
