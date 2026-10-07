enum PayRentAmountOption { fullBalance, other }

enum PayRentMethod { mpesa, bankTransfer }

enum PayRentStep { form, confirming, received }

/// Safaricom's per-transaction ceiling for M-Pesa.
const int kMpesaMaxPerTransaction = 250000;
