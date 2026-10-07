import 'package:flutter/foundation.dart';
import '../../../../core/billing/billing_engine.dart';
import '../../../../core/billing/billing_models.dart';
import '../../../../core/models/payment_receipt.dart';

/// Everything the tenant app shows about the signed-in tenant's money,
/// derived once from their slice of the seed.
@immutable
class TenantAccountState {
  const TenantAccountState._({
    required this.seed,
    required this.tenancy,
    required this.tenant,
    required this.unit,
    required this.property,
    required this.company,
    required this.bills,
    required this.receipts,
  });

  factory TenantAccountState.fromSeed(BillingSeed seed) {
    final engine = BillingEngine(seed);
    final tenancy = seed.tenancies.single;
    final bills = engine.ledger(tenancy);
    final tenant = engine.tenantOf(tenancy);
    final unit = engine.unitOf(tenancy);
    final property = engine.propertyOf(tenancy);
    final company = engine.companyOf(tenancy);

    final receipts = <PaymentReceipt>[
      for (final bill in bills)
        for (final payment in bill.payments)
          PaymentReceipt(
            receiptNumber: payment.receiptNumber,
            companyName: company.name,
            kraPin: company.kraPin,
            amount: payment.amount,
            tenantName: tenant.name,
            unit: '${unit.label} · ${property.name}',
            date: payment.date,
            time: payment.time,
            method: payment.method.label,
            reference: payment.reference,
            forDescription: engine.receiptDescription(bill, payment),
            billMonth: bill.month,
          ),
    ].reversed.toList(growable: false);

    return TenantAccountState._(
      seed: seed,
      tenancy: tenancy,
      tenant: tenant,
      unit: unit,
      property: property,
      company: company,
      bills: bills,
      receipts: receipts,
    );
  }

  final BillingSeed seed;
  final Tenancy tenancy;
  final Tenant tenant;
  final Unit unit;
  final Property property;

  /// The landlord this tenancy belongs to (its name, Paybill and rules).
  final Company company;

  /// Oldest first.
  final List<MonthlyBill> bills;

  /// Newest first.
  final List<PaymentReceipt> receipts;

  MonthlyBill? get currentBill => bills.isEmpty ? null : bills.last;

  /// What the tenant owes right now; negative means they are in credit.
  int get balance => currentBill?.outstanding ?? 0;

  bool get isActive => tenancy.isActive;

  /// Paybill account number and bank reference, e.g. 'RC-5A'.
  String get accountNumber => '${property.accountPrefix}-${unit.label}';

  String get unitTitle => '${property.name} · ${unit.label}';

  /// Everything paid since the landlord joined Makazi (ledgerStartMonth).
  int get totalPaid => seed.payments.fold(0, (sum, p) => sum + p.amount);

  /// Deposit held for the tenant until they move out.
  int get depositHeld => isActive ? tenancy.deposit : 0;

  /// The staff member who manages this tenant's property.
  StaffMember? get manager {
    for (final member in seed.staff) {
      if (member.id == property.managerId) return member;
    }
    return null;
  }

  /// Former tenants: records (and this app) stay available until this date.
  String? get recordsKeptUntil => tenancy.moveOut == null
      ? null
      : BillingDates.addMonthsToDate(
          tenancy.moveOut!,
          company.settings.recordRetentionMonths,
        );

  /// Before any bill exists: the 1st on which the first one is issued.
  String? get firstBillDate {
    if (bills.isNotEmpty) return null;
    final nextMonth = BillingDates.addMonths(
      BillingDates.monthOf(seed.asOf),
      1,
    );
    final moveInMonth = BillingDates.monthOf(tenancy.moveIn);
    final month = moveInMonth.compareTo(nextMonth) > 0
        ? moveInMonth
        : nextMonth;
    return '$month-01';
  }

  MonthlyBill? billFor(String month) {
    for (final bill in bills) {
      if (bill.month == month) return bill;
    }
    return null;
  }
}
