import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auth_models.dart';

/// Four dots and an on-screen keypad. Avoids the system keyboard, which on
/// iOS has no Done key for numbers and can offer to save the PIN.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.footer,
    this.enabled = true,
  });

  /// Called with the full PIN; the pad then clears itself.
  final ValueChanged<String> onCompleted;

  /// Shown in the bottom-left key slot (e.g. "Forgot PIN?").
  final Widget? footer;
  final bool enabled;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  void _tap(String digit) {
    if (!widget.enabled || _digits.length >= kPinLength) return;
    setState(() => _digits += digit);
    if (_digits.length == kPinLength) {
      final pin = _digits;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() => _digits = '');
        widget.onCompleted(pin);
      });
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String digit) => _PadKey(
      key: ValueKey('pin_key_$digit'),
      onTap: () => _tap(digit),
      child: Text(
        digit,
        style: AppTypography.sans(
          fontSize: 26,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );

    return Column(
      children: [
        Semantics(
          label: '${_digits.length} of $kPinLength digits entered',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < kPinLength; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _digits.length
                        ? AppColors.forestGreen
                        : Colors.transparent,
                    border: Border.all(
                      color: AppColors.forestGreen,
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: Center(child: widget.footer ?? const SizedBox.shrink()),
            ),
            key('0'),
            _PadKey(
              key: const ValueKey('pin_key_backspace'),
              onTap: _backspace,
              filled: false,
              child: const Icon(
                Icons.backspace_outlined,
                color: AppColors.textSecondary,
                semanticLabel: 'Delete',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    super.key,
    required this.onTap,
    required this.child,
    this.filled = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: filled ? AppColors.cardBackground : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 76, height: 76, child: Center(child: child)),
        ),
      ),
    );
  }
}
