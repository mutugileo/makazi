import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../billing/presentation/state/tenant_account_providers.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/models/chat_message.dart';
import '../state/messages_notifier.dart';
import '../state/messages_providers.dart';
import '../widgets/typing_indicator.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      return;
    }
    ref.read(messagesProvider.notifier).dispatchUserMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final isManagerTyping = ref.watch(managerTypingProvider);
    final account = ref.watch(tenantAccountProvider);
    final managerName = account.manager?.name ?? account.company.name;
    final managerInitials = managerName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    final companyShortName = account.company.name.split(' ').first;
    final theme = Theme.of(context);
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final systemBottomPadding = mediaQuery.padding.bottom;
    final inputBottomPadding = isKeyboardOpen
        ? AppSpacing.xs
        : systemBottomPadding + 74.0;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.avatarBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        managerInitials,
                        style: AppTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.avatarText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          managerName,
                          style: AppTypography.editorialSerif(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Property manager · $companyShortName',
                          style: AppTypography.sans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Expanded(
              child: messages.isEmpty && !isManagerTyping
                  ? Center(
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No messages yet',
                        message: 'Ask $managerName anything about your home.',
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      itemCount: messages.length + (isManagerTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return TypingIndicator(senderName: managerName);
                        }
                        final message = messages[index];
                        return _ChatMessageItem(
                          message: message,
                          onRetry: () => ref
                              .read(messagesProvider.notifier)
                              .retry(message.id),
                        );
                      },
                    ),
            ),
            AnimatedPadding(
              duration: motion.shortFeedbackDuration,
              curve: motion.standardEasing,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                inputBottomPadding,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 6, 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: AppTypography.sans(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: AppTypography.sans(
                            fontSize: 15,
                            color: AppColors.textSubtle,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Send message',
                      child: GestureDetector(
                        onTap: _sendMessage,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.mintAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: AppColors.pureWhite,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageItem extends StatelessWidget {
  const _ChatMessageItem({required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (message.isUserMessage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.mintAccent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: AppTypography.sans(
                  fontSize: 14,
                  color: AppColors.pureWhite,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            switch (message.delivery) {
              MessageDelivery.sent => Text(
                message.timestamp,
                style: AppTypography.sans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              MessageDelivery.sending => Text(
                'Sending…',
                style: AppTypography.sans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              MessageDelivery.failed => GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Not sent · Tap to retry',
                  style: AppTypography.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusUnpaidText,
                  ),
                ),
              ),
            },
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              message.text,
              style: AppTypography.sans(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.timestamp,
            style: AppTypography.sans(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
