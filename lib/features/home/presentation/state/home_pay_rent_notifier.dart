import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/billing/payment_claim.dart';
import '../../../../core/billing/payment_message_validator.dart';
import '../../../../core/data/supabase_billing_providers.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import 'home_pay_rent_ui_state.dart';

/// Pay rent: the tenant pays the Paybill or bank outside the app, then sends
/// the confirmation message here. The manager matches it against their
/// statement; only their confirmation changes the balance.
class HomePayRentNotifier extends Notifier<HomePayRentUiState> {
  @override
  HomePayRentUiState build() => const HomePayRentUiState();

  void openPayRent() => state = const HomePayRentUiState(isOpen: true);

  void openPayRentForEdit(PaymentClaim claim) => state = HomePayRentUiState(
    isOpen: true,
    message: claim.message ?? '',
    editingClaimId: claim.id,
  );

  void closePayRent() => state = const HomePayRentUiState();

  void updateMessage(String message) {
    state = state.copyWith(message: message, errorText: () => null);
  }

  Future<void> sendMessage() async {
    if (!state.canSend) return;
    final trimmed = state.message.trim();
    final validationError = validatePaymentMessage(trimmed);
    if (validationError != null) {
      state = state.copyWith(errorText: () => validationError);
      return;
    }
    state = state.copyWith(isSending: true, errorText: () => null);
    final tenancyId = ref.read(tenantAccountProvider).tenancy.id;
    final editingId = state.editingClaimId;
    try {
      final repo = ref.read(paymentClaimsRepositoryProvider);
      final claim = editingId != null
          ? await repo.updateClaim(claimId: editingId, message: trimmed)
          : await repo.submit(tenancyId: tenancyId, message: trimmed);
      ref.invalidate(paymentClaimsProvider);
      if (!ref.mounted) return;
      state = state.copyWith(isSending: false, sentClaim: () => claim);
    } on PaymentClaimRefused catch (refused) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSending: false,
        errorText: () => refused.message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSending: false,
        errorText: () =>
            "Couldn't send the message. Check your connection and try again.",
      );
    }
  }
}
