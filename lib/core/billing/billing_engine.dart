import 'billing_models.dart';

// Dart port of PropAdmin/src/lib/billing.ts. Keep the two in step: the
// parity test runs this engine over shared/billing-seed.json and compares
// every bill with shared/billing-expected.json. Rules: shared/README.md.

abstract final class BillingDates {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String monthOf(String isoDate) => isoDate.substring(0, 7);

  static String addMonths(String month, int delta) {
    final year = int.parse(month.substring(0, 4));
    final mon = int.parse(month.substring(5, 7));
    final index = year * 12 + (mon - 1) + delta;
    final y = index ~/ 12;
    final m = index % 12 + 1;
    return '$y-${m.toString().padLeft(2, '0')}';
  }

  static List<String> monthsBetween(String from, String to) {
    final out = <String>[];
    for (var m = from; m.compareTo(to) <= 0; m = addMonths(m, 1)) {
      out.add(m);
    }
    return out;
  }

  static int daysInMonth(String month) {
    final year = int.parse(month.substring(0, 4));
    final mon = int.parse(month.substring(5, 7));
    return DateTime.utc(year, mon + 1, 0).day;
  }

  /// Same day n months later, clamped to the month's last day (as the admin).
  static String addMonthsToDate(String isoDate, int delta) {
    final month = addMonths(monthOf(isoDate), delta);
    final day = int.parse(isoDate.substring(8, 10));
    final clamped = day < daysInMonth(month) ? day : daysInMonth(month);
    return '$month-${clamped.toString().padLeft(2, '0')}';
  }

  static String dueDateOf(String month, int dueDay) =>
      '$month-${dueDay.toString().padLeft(2, '0')}';

  static int daysBetween(String from, String to) => DateTime.parse(
    '${to}T00:00:00Z',
  ).difference(DateTime.parse('${from}T00:00:00Z')).inDays;

  static String monthLabel(String month) {
    final m = int.parse(month.substring(5, 7));
    return '${_monthNames[m - 1]} ${month.substring(0, 4)}';
  }

  static String shortMonth(String month) =>
      _monthNames[int.parse(month.substring(5, 7)) - 1].substring(0, 3);

  /// '2026-10-05' -> '05 Oct 2026'
  static String formatDate(String isoDate) {
    final m = int.parse(isoDate.substring(5, 7));
    return '${isoDate.substring(8, 10)} ${_monthNames[m - 1].substring(0, 3)} '
        '${isoDate.substring(0, 4)}';
  }

  /// '2026-10-05' -> '5 Oct'
  static String formatDayMonth(String isoDate) {
    final m = int.parse(isoDate.substring(5, 7));
    final d = int.parse(isoDate.substring(8, 10));
    return '$d ${_monthNames[m - 1].substring(0, 3)}';
  }
}

/// 45000 -> 'KES 45,000'; -5840 -> '−KES 5,840'
String formatKes(int amount) {
  final sign = amount < 0 ? '−' : '';
  return '${sign}KES ${groupThousands(amount.abs())}';
}

String groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Rent for a mid-month move-in: days left in the month, counting the
/// move-in day. A move-in on the 1st pays the full month (days == null).
({int amount, ProratedDays? days}) proratedRent(int rent, String moveIn) {
  final of = BillingDates.daysInMonth(BillingDates.monthOf(moveIn));
  final days = of - int.parse(moveIn.substring(8, 10)) + 1;
  if (days >= of) return (amount: rent, days: null);
  return (
    amount: (rent * days / of).round(),
    days: ProratedDays(days: days, of: of),
  );
}

class BillingEngine {
  const BillingEngine(this.seed);

  final BillingSeed seed;

  Unit unitOf(Tenancy tenancy) =>
      seed.units.firstWhere((u) => u.id == tenancy.unitId);

  Property propertyOf(Tenancy tenancy) {
    final unit = unitOf(tenancy);
    return seed.properties.firstWhere((p) => p.id == unit.propertyId);
  }

  Company companyOf(Tenancy tenancy) =>
      seed.companyById(propertyOf(tenancy).companyId);

  Tenant tenantOf(Tenancy tenancy) =>
      seed.tenants.firstWhere((t) => t.id == tenancy.tenantId);

  int? _reading(String unitId, String month) {
    return seed.meterReadings[unitId]?[month];
  }

  WaterUsage? _waterFor(String unitId, String month, int rate, int? opening) {
    final current = _reading(unitId, month);
    if (current == null) return null;
    final previous =
        opening ?? _reading(unitId, BillingDates.addMonths(month, -1));
    if (previous == null) return null;
    final units = current < previous ? 0 : current - previous;
    return WaterUsage(
      previousReading: previous,
      currentReading: current,
      units: units,
      rate: rate,
    );
  }

  (String, String)? billingWindow(Tenancy tenancy) {
    final asOfMonth = BillingDates.monthOf(seed.asOf);
    final moveInMonth = BillingDates.monthOf(tenancy.moveIn);
    final start = companyOf(tenancy).settings.ledgerStartMonth;
    final first = moveInMonth.compareTo(start) > 0 ? moveInMonth : start;

    final unitReadings =
        seed.meterReadings[tenancy.unitId]?.keys.toList() ?? const <String>[];
    final tenancyPayments = seed.payments
        .where((p) => p.tenancyId == tenancy.id)
        .map((p) => BillingDates.monthOf(p.date))
        .toList();
    final candidates = [asOfMonth, ...unitReadings, ...tenancyPayments]..sort();
    final maxActive = candidates.last;

    final finalMonth = tenancy.moveOut == null
        ? maxActive
        : BillingDates.addMonths(BillingDates.monthOf(tenancy.moveOut!), 1);
    final last = finalMonth.compareTo(maxActive) < 0 ? finalMonth : maxActive;
    return first.compareTo(last) <= 0 ? (first, last) : null;
  }

  List<MonthlyBill> ledger(Tenancy tenancy) {
    final window = billingWindow(tenancy);
    if (window == null) return const [];

    final unit = unitOf(tenancy);
    final property = propertyOf(tenancy);
    final settings = companyOf(tenancy).settings;
    final moveInMonth = BillingDates.monthOf(tenancy.moveIn);
    final finalMonth = tenancy.moveOut == null
        ? null
        : BillingDates.addMonths(BillingDates.monthOf(tenancy.moveOut!), 1);
    final payments =
        seed.payments.where((p) => p.tenancyId == tenancy.id).toList()..sort(
          (a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'),
        );

    final bills = <MonthlyBill>[];
    var balanceBf = tenancy.openingBalance;

    for (final month in BillingDates.monthsBetween(window.$1, window.$2)) {
      final kind = month == finalMonth
          ? BillKind.finalBill
          : month == moveInMonth &&
                moveInMonth.compareTo(settings.ledgerStartMonth) >= 0
          ? BillKind.moveIn
          : BillKind.monthly;

      final lines = <BillLine>[];
      WaterUsage? water;
      ProratedDays? rentDays;
      final rates = property.ratesFor(month);
      // The first water bill after a move-in starts from the move-in reading.
      final opening =
          tenancy.openingReading != null &&
              BillingDates.addMonths(moveInMonth, 1) == month
          ? tenancy.openingReading
          : null;

      switch (kind) {
        case BillKind.moveIn:
          final rent = proratedRent(tenancy.rent, tenancy.moveIn);
          rentDays = rent.days;
          lines
            ..add(BillLine(kind: BillLineKind.deposit, amount: tenancy.deposit))
            ..add(BillLine(kind: BillLineKind.rent, amount: rent.amount))
            ..add(
              BillLine(kind: BillLineKind.garbage, amount: rates.garbageFee),
            );
          final currentReading = _reading(unit.id, month);
          if (currentReading != null &&
              tenancy.openingReading != null &&
              currentReading > tenancy.openingReading!) {
            final units = currentReading - tenancy.openingReading!;
            water = WaterUsage(
              previousReading: tenancy.openingReading!,
              currentReading: currentReading,
              units: units,
              rate: rates.waterRate,
            );
            lines.add(BillLine(kind: BillLineKind.water, amount: water.amount));
          }
        case BillKind.monthly:
          water = _waterFor(unit.id, month, rates.waterRate, opening);
          lines.add(BillLine(kind: BillLineKind.rent, amount: tenancy.rent));
          if (water != null && water.units > 0) {
            lines.add(BillLine(kind: BillLineKind.water, amount: water.amount));
          }
          lines.add(
            BillLine(kind: BillLineKind.garbage, amount: rates.garbageFee),
          );
        case BillKind.finalBill:
          water = _waterFor(unit.id, month, rates.waterRate, opening);
          if (water != null && water.units > 0) {
            lines.add(BillLine(kind: BillLineKind.water, amount: water.amount));
          }
          lines.add(
            BillLine(
              kind: BillLineKind.depositApplied,
              amount: -tenancy.deposit,
            ),
          );
          final afterDeposit =
              balanceBf + (water?.amount ?? 0) - tenancy.deposit;
          if (afterDeposit < 0) {
            lines.add(
              BillLine(kind: BillLineKind.depositRefund, amount: -afterDeposit),
            );
          }
      }

      final monthPayments = payments
          .where((p) => BillingDates.monthOf(p.date) == month)
          .toList(growable: false);
      final bill = MonthlyBill(
        tenancyId: tenancy.id,
        month: month,
        kind: kind,
        dueDate: BillingDates.dueDateOf(month, settings.dueDay),
        graceDate: BillingDates.dueDateOf(month, settings.graceDay),
        rentDays: rentDays,
        lines: List.unmodifiable(lines),
        water: water,
        balanceBf: balanceBf,
        amountPaid: monthPayments.fold(0, (sum, p) => sum + p.amount),
        payments: monthPayments,
      );
      bills.add(bill);
      balanceBf = bill.outstanding;
    }

    return List.unmodifiable(bills);
  }

  /// The bill a payment landed on and how it reads on the receipt.
  String receiptDescription(MonthlyBill bill, Payment payment) {
    final label = BillingDates.monthLabel(bill.month);
    final base = switch (bill.kind) {
      BillKind.moveIn => 'Move-in bill, $label',
      BillKind.finalBill => 'Final bill, $label',
      BillKind.monthly => 'Bill, $label',
    };
    var paidSoFar = 0;
    for (final p in bill.payments) {
      paidSoFar += p.amount;
      if (p.receiptNumber == payment.receiptNumber) break;
    }
    return bill.totalDue - paidSoFar > 0 ? '$base (part)' : base;
  }
}
