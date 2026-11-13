import 'package:supabase_flutter/supabase_flutter.dart';
import '../billing/payment_claim.dart';
import '../billing/payment_message_validator.dart';
import 'supabase_billing_repository.dart';

/// Where the tenant's payment messages go: the database in the live app, this
/// phone in the offline demo.
abstract interface class PaymentClaimsRepository {
  /// Sends a pasted confirmation for the manager to check. Throws
  /// [PaymentClaimRefused] when it can't be accepted.
  Future<PaymentClaim> submit({
    required String tenancyId,
    required String message,
  });

  /// Messages from the last 30 days that still matter to the tenant: waiting
  /// for the manager, or not confirmed. Newest first.
  Future<List<PaymentClaim>> fetchOpen({required String tenancyId});
}

class SupabasePaymentClaimsRepository implements PaymentClaimsRepository {
  SupabasePaymentClaimsRepository({this.client});

  /// For tests; the app uses the initialised Supabase client.
  final SupabaseClient? client;

  SupabaseClient get _sb => client ?? Supabase.instance.client;

  // submit_payment_claim raises these with a message meant for the tenant.
  static const _refusalCodes = {'22023', '23505', '42501', '54000'};

  @override
  Future<PaymentClaim> submit({
    required String tenancyId,
    required String message,
  }) async {
    try {
      final row = await _sb
          .rpc(
            'submit_payment_claim',
            params: {'p_tenancy_id': tenancyId, 'p_message': message},
          )
          .timeout(const Duration(seconds: 15));
      return claimFromRow((row as Map).cast<String, dynamic>());
    } on PostgrestException catch (e) {
      if (_refusalCodes.contains(e.code)) throw PaymentClaimRefused(e.message);
      rethrow;
    }
  }

  @override
  Future<List<PaymentClaim>> fetchOpen({required String tenancyId}) async {
    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    final rows = await _sb
        .from('payment_claims')
        .select('id, status, reference, amount, review_note, created_at')
        .eq('tenancy_id', tenancyId)
        .neq('status', PaymentClaimStatus.confirmed.wire)
        .gte('created_at', since)
        .order('created_at', ascending: false)
        .limit(10)
        .timeout(const Duration(seconds: 10));
    return [for (final row in rows) claimFromRow(row.cast<String, dynamic>())];
  }

  static PaymentClaim claimFromRow(Map<String, dynamic> row) => PaymentClaim(
    id: row['id'] as String,
    status: PaymentClaimStatus.fromWire(row['status'] as String),
    createdAt: nairobiIso(row['created_at'] as String),
    reference: row['reference'] as String?,
    amount: (row['amount'] as num?)?.toInt(),
    reviewNote: row['review_note'] as String?,
  );
}

/// Offline demo: messages stay on this phone and wait, as no manager is
/// there to confirm them.
class DemoPaymentClaimsRepository implements PaymentClaimsRepository {
  final _claims = <PaymentClaim>[];

  @override
  Future<PaymentClaim> submit({
    required String tenancyId,
    required String message,
  }) async {
    final validationError = validatePaymentMessage(message);
    if (validationError != null) {
      throw PaymentClaimRefused(validationError);
    }
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final claim = PaymentClaim(
      id: 'demo-${_claims.length + 1}',
      status: PaymentClaimStatus.pending,
      createdAt: '${now.toIso8601String().substring(0, 19)}+03:00',
    );
    _claims.insert(0, claim);
    return claim;
  }

  @override
  Future<List<PaymentClaim>> fetchOpen({required String tenancyId}) async =>
      List.unmodifiable(_claims);
}
