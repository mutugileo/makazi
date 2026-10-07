import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_models.dart';
import '../state/auth_providers.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/pin_pad.dart';

/// Choose a PIN, then enter it again to confirm.
class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String? _first;

  void _onPin(String pin) {
    final notifier = ref.read(authProvider.notifier);
    if (_first == null) {
      if (notifier.checkNewPin(pin)) setState(() => _first = pin);
      return;
    }
    final first = _first!;
    setState(() => _first = null);
    notifier.createPin(pin: first, confirmation: pin);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final confirming = _first != null;

    return PopScope(
      canPop: !confirming,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _first = null);
      },
      child: AuthScaffold(
        title: confirming ? 'Confirm your PIN' : 'Create a PIN',
        subtitle: confirming
            ? 'Enter the same $kPinLength digits again.'
            : 'You\'ll use this $kPinLength-digit PIN to open Makazi on this '
                  'phone. Don\'t reuse your M-Pesa PIN.',
        child: Column(
          children: [
            AuthErrorText(state.errorText),
            const SizedBox(height: 24),
            PinPad(key: ValueKey('pin_pad_$confirming'), onCompleted: _onPin),
          ],
        ),
      ),
    );
  }
}
