import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data_mode.dart';
import 'payment_claims_repository.dart';
import 'supabase_billing_repository.dart';

final supabaseBillingRepositoryProvider = Provider<SupabaseBillingRepository>((
  ref,
) {
  return SupabaseBillingRepository();
});

final paymentClaimsRepositoryProvider = Provider<PaymentClaimsRepository>(
  (ref) => ref.watch(liveDataProvider)
      ? SupabasePaymentClaimsRepository()
      : DemoPaymentClaimsRepository(),
);
