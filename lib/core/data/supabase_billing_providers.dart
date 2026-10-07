import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_billing_repository.dart';

final supabaseBillingRepositoryProvider = Provider<SupabaseBillingRepository>((
  ref,
) {
  return SupabaseBillingRepository();
});
