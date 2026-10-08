enum PayRentAmountOption { fullBalance, other }

enum PayRentMethod { mpesa, bankTransfer }

/// form → awaitingApproval (the M-Pesa prompt on the phone) → confirming →
/// received. Declining goes back to the form.
enum PayRentStep { form, awaitingApproval, confirming, received }

/// Safaricom's per-transaction ceiling for M-Pesa.
const int kMpesaMaxPerTransaction = 250000;
