/// Validates a pasted payment confirmation message before it is sent to the
/// manager, mirroring `app.parse_payment_message` and `submit_payment_claim`.
String? validatePaymentMessage(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length < 20) {
    return 'Paste the whole confirmation message';
  }
  if (trimmed.length > 1000) {
    return 'That message is too long. Paste only the confirmation message.';
  }

  final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  final reference = _extractReference(normalized);
  final amount = _extractAmount(normalized);

  if (reference == null || amount == null) {
    return 'Paste the full M-Pesa or bank confirmation message, including '
        'the reference and amount.';
  }
  return null;
}

String? _extractReference(String normalized) {
  final labelledRef = RegExp(
    r'ref(?:erence)?\s*[:.#-]?\s*([A-Za-z0-9]{10})\b',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (labelledRef != null) return labelledRef.group(1)!.toUpperCase();

  final leadingConfirmed = RegExp(
    r'\b([A-Za-z0-9]{10})\b\s*confirmed',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (leadingConfirmed != null) return leadingConfirmed.group(1)!.toUpperCase();

  final mixedCode = RegExp(
    r'\b((?=[A-Z0-9]*[0-9])(?=[A-Z0-9]*[A-Z])[A-Z0-9]{10})\b',
  ).firstMatch(normalized);
  return mixedCode?.group(1);
}

int? _extractAmount(String normalized) {
  final match = RegExp(
    r'(?:KES|KSH)\.?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (match == null) return null;

  final parsed = double.tryParse(match.group(1)!.replaceAll(',', ''));
  if (parsed == null) return null;

  final rounded = parsed.round();
  if (rounded < 1 || rounded > 1000000) return null;
  return rounded;
}
