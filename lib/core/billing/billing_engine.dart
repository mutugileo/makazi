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

  /// Billing cycles run from the 4th to the 3rd of the next month, starting
  /// with the December 2026 cycle; earlier cycles were calendar months, so
  /// bills already issued never move. A cycle is named after the month it
  /// starts in.
  static const cycleStartDay = 4;
  static const firstCycleOnStartDay = '2026-12';

  /// The day a billing cycle starts, which is when its bill is issued.
  static String cycleStart(String month) =>
      month.compareTo(firstCycleOnStartDay) >= 0
      ? '$month-${cycleStartDay.toString().padLeft(2, '0')}'
      : '$month-01';

  /// The billing cycle a date falls in.
  static String cycleOf(String isoDate) {
    final month = monthOf(isoDate);
    return month.compareTo(firstCycleOnStartDay) >= 0 &&
            int.parse(isoDate.substring(8, 10)) < cycleStartDay
        ? addMonths(month, -1)
        : month;
  }

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

  /// Water for a month: its reading minus the last one before it since the
  /// tenancy began (or the move-in reading). A skipped month is billed on the
  /// next reading, covering all the water used since.
  WaterUsage? _waterFor(
    String unitId,
    String month,
    int rate,
    String since,
    int? opening,
  ) {
    final current = _reading(unitId, month);
    if (current == null) return null;
    final readings = seed.meterReadings[unitId] ?? const <String, int>{};
    final earlier =
        readings.keys
            .where((m) => m.compareTo(since) >= 0 && m.compareTo(month) < 0)
            .toList()
          ..sort();
    final previous = earlier.isNotEmpty ? readings[earlier.last] : opening;
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
    final asOfMonth = BillingDates.cycleOf(seed.asOf);
    final moveInMonth = BillingDates.cycleOf(tenancy.moveIn);
    final start = companyOf(tenancy).settings.ledgerStartMonth;
    final first = moveInMonth.compareTo(start) > 0 ? moveInMonth : start;

    final unitReadings =
        seed.meterReadings[tenancy.unitId]?.keys.toList() ?? const <String>[];
    final tenancyPayments = seed.payments
        .where((p) => p.tenancyId == tenancy.id)
        .map((p) => BillingDates.cycleOf(p.date))
        .toList();
    final candidates = [asOfMonth, ...unitReadings, ...tenancyPayments]..sort();
    final maxActive = candidates.last;

    final finalMonth = tenancy.moveOut == null
        ? maxActive
        : BillingDates.addMonths(BillingDates.cycleOf(tenancy.moveOut!), 1);
    var last = finalMonth.compareTo(maxActive) < 0 ? finalMonth : maxActive;
    // Paid before the first bill (deposit and rent ahead of moving in): issue
    // the move-in bill so the payment has a bill to count against.
    if (last.compareTo(first) < 0 &&
        tenancyPayments.any((m) => m.compareTo(first) < 0)) {
      last = first;
    }
    return first.compareTo(last) <= 0 ? (first, last) : null;
  }

  List<MonthlyBill> ledger(Tenancy tenancy) {
    final window = billingWindow(tenancy);
    if (window == null) return const [];

    final unit = unitOf(tenancy);
    final property = propertyOf(tenancy);
    final settings = companyOf(tenancy).settings;
    final moveInMonth = BillingDates.cycleOf(tenancy.moveIn);
    final finalMonth = tenancy.moveOut == null
        ? null
        : BillingDates.addMonths(BillingDates.cycleOf(tenancy.moveOut!), 1);
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
      final rates = property.ratesFor(month);

      switch (kind) {
        case BillKind.moveIn:
          lines
            ..add(BillLine(kind: BillLineKind.deposit, amount: tenancy.deposit))
            ..add(
              BillLine(
                kind: BillLineKind.rent,
                amount: tenancy.moveInRent ?? tenancy.rent,
              ),
            );
          final moveInGarbage = tenancy.moveInGarbage ?? 0;
          if (moveInGarbage > 0) {
            lines.add(
              BillLine(kind: BillLineKind.garbage, amount: moveInGarbage),
            );
          }
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
          water = _waterFor(
            unit.id,
            month,
            rates.waterRate,
            moveInMonth,
            tenancy.openingReading,
          );
          lines.add(BillLine(kind: BillLineKind.rent, amount: tenancy.rent));
          if (water != null && water.units > 0) {
            lines.add(BillLine(kind: BillLineKind.water, amount: water.amount));
          }
          lines.add(
            BillLine(kind: BillLineKind.garbage, amount: rates.garbageFee),
          );
        case BillKind.finalBill:
          water = _waterFor(
            unit.id,
            month,
            rates.waterRate,
            moveInMonth,
            tenancy.openingReading,
          );
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

      // A payment counts towards the cycle it was made in; payments made
      // before the first bill count towards it.
      final monthPayments = payments
          .where((p) {
            final paidIn = BillingDates.cycleOf(p.date);
            return paidIn == month ||
                (month == window.$1 && paidIn.compareTo(month) < 0);
          })
          .toList(growable: false);
      final bill = MonthlyBill(
        tenancyId: tenancy.id,
        month: month,
        kind: kind,
        dueDate: BillingDates.dueDateOf(month, settings.dueDay),
        graceDate: BillingDates.dueDateOf(month, settings.graceDay),
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
