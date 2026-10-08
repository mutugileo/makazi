import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FaqItem {
  const FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

/// FAQ for the tenant app. Keep answers true to the product: anything not
/// built yet is said so, not promised.
const List<FaqItem> kTenantFaq = [
  FaqItem(
    'How do I sign in?',
    'Use the phone number your property manager registered and the one-time '
        'password they gave you. You will be asked to set your own password, '
        'then create a PIN for quick unlock.',
  ),
  FaqItem(
    'Can I unlock with my fingerprint or face?',
    'Yes, if your phone supports it. You can turn it on after you create your PIN.',
  ),
  FaqItem(
    'Can I pay rent in the app?',
    'The app shows your balance and the paybill details to pay with M-Pesa. '
        'Makazi records the payment once M-Pesa confirms it. Some companies '
        'run a test mode, where payments are simulated and flagged as test payments.',
  ),
  FaqItem(
    'Where can I see my receipts and statement?',
    'Both are in the app. Each payment has its receipt number.',
  ),
  FaqItem(
    'How do I report a repair?',
    'Open the repairs section, describe the problem and send it. You can track '
        'its status. Once it is assigned you will see who is coming, their number '
        'and the expected visit time.',
  ),
  FaqItem(
    'How do I contact my manager?',
    'Use Messages. Your manager replies in the same thread, and you can see '
        'when they are typing.',
  ),
  FaqItem(
    'Will I get payment reminders?',
    'Your manager can send reminders. They show on Home and as a notification '
        'while the app is open. No SMS or email is sent.',
  ),
  FaqItem(
    'Who can see my information?',
    'Only your own balance, receipts, repairs and messages. Your manager sees '
        'your account in the admin.',
  ),
];

/// Opens the tenant FAQ as a modal dialog.
Future<void> showTenantFaqDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('tenant_faq_dialog'),
      title: Text(
        'Frequently asked questions',
        style: AppTypography.sans(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in kTenantFaq)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
                  title: Text(
                    item.question,
                    style: AppTypography.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.answer,
                        style: AppTypography.sans(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
