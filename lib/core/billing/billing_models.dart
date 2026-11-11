import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';

// Mirrors the types in PropAdmin/src/lib/billing.ts and the JSON shape of
// shared/billing-seed.json. Amounts are whole Kenyan shillings.

enum PropertyType {
  apartments('Apartments'),
  houses('Houses');

  const PropertyType(this.label);
  final String label;

  static PropertyType fromJson(String value) =>
      PropertyType.values.firstWhere((t) => t.name == value);
}

enum PaymentMethod {
  mpesa('M-Pesa'),
  bank('Bank');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod fromJson(String value) =>
      PaymentMethod.values.firstWhere((m) => m.label == value);
}

enum BillKind {
  moveIn('move-in'),
  monthly('monthly'),
  finalBill('final');

  const BillKind(this.wire);
  final String wire;
}

enum BillStatus {
  paid('Paid'),
  partial('Partial'),
  unpaid('Unpaid'),
  credit('Credit');

  const BillStatus(this.label);
  final String label;
}

enum BillLineKind {
  rent('Rent'),
  water('Water'),
  garbage('Garbage'),
  deposit('Deposit'),
  depositApplied('Deposit applied'),
  depositRefund('Deposit refunded');

  const BillLineKind(this.label);
  final String label;
}

/// Landlord custom brand theme configured via MakaziSuperAdmin.
@immutable
class CompanyTheme {
  const CompanyTheme({
    this.preset = 'forest',
    this.primaryHex = '#0D382B',
    this.navBgHex = '#0A261F',
    this.accentHex = '#C6EE58',
    this.buttonHex,
    this.progressHex,
    this.logoUrl,
  });

  factory CompanyTheme.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanyTheme();
    return CompanyTheme(
      preset: json['preset'] as String? ?? 'forest',
      primaryHex: json['primary'] as String? ?? '#0D382B',
      navBgHex: json['navBg'] as String? ?? '#0A261F',
      accentHex: json['accent'] as String? ?? '#C6EE58',
      buttonHex: json['button'] as String?,
      progressHex: json['progress'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  final String preset;
  final String primaryHex;
  final String navBgHex;
  final String accentHex;

  /// Main call-to-action buttons (Pay now, New request). Falls back to accent.
  final String? buttonHex;

  /// Rent progress bar fill. Falls back to accent.
  final String? progressHex;
  final String? logoUrl;

  Color get primaryColor => _parseHex(primaryHex, const Color(0xFF0D382B));
  Color get navBgColor => _parseHex(navBgHex, const Color(0xFF0A261F));
  Color get accentColor => _parseHex(accentHex, const Color(0xFFC6EE58));
  Color get buttonColor =>
      buttonHex == null ? accentColor : _parseHex(buttonHex!, accentColor);
  Color get progressColor =>
      progressHex == null ? accentColor : _parseHex(progressHex!, accentColor);

  /// Text and icons on top of [buttonColor].
  Color get onButtonColor => buttonColor.computeLuminance() > 0.35
      ? const Color(0xFF071A2C)
      : const Color(0xFFFFFFFF);

  /// Accessible text/icon color for elements rendered on top of [accentColor].
  Color get onAccentColor => accentColor.computeLuminance() > 0.35
      ? (navBgColor.computeLuminance() < 0.2
            ? navBgColor
            : const Color(0xFF071A2C))
      : const Color(0xFFFFFFFF);

  /// Accessible text/icon color for elements rendered on top of [primaryColor].
  Color get onPrimaryColor => primaryColor.computeLuminance() > 0.35
      ? const Color(0xFF071A2C)
      : const Color(0xFFFFFFFF);

  /// Accessible text/icon color for elements rendered on top of [navBgColor].
  Color get onNavBgColor => navBgColor.computeLuminance() > 0.35
      ? const Color(0xFF071A2C)
      : const Color(0xFFFFFFFF);

  static Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Map<String, dynamic> toJson() => {
    'preset': preset,
    'primary': primaryHex,
    'navBg': navBgHex,
    'accent': accentHex,
    if (buttonHex != null) 'button': buttonHex,
    if (progressHex != null) 'progress': progressHex,
    if (logoUrl != null) 'logoUrl': logoUrl,
  };
}

/// Billing rules a landlord chooses for themselves.
@immutable
class PropertyPaymentDetail {
  const PropertyPaymentDetail({
    this.mpesaPaybill,
    this.bankName,
    this.bankAccount,
    this.pesalinkPhone,
    this.pesalinkPaybill,
    this.pesalinkNotes,
  });

  factory PropertyPaymentDetail.fromJson(Map<String, dynamic> json) =>
      PropertyPaymentDetail(
        mpesaPaybill: json['mpesaPaybill'] as String?,
        bankName: json['bankName'] as String?,
        bankAccount: json['bankAccount'] as String?,
        pesalinkPhone: json['pesalinkPhone'] as String?,
        pesalinkPaybill: json['pesalinkPaybill'] as String?,
        pesalinkNotes: json['pesalinkNotes'] as String?,
      );

  final String? mpesaPaybill;
  final String? bankName;
  final String? bankAccount;
  final String? pesalinkPhone;
  final String? pesalinkPaybill;
  final String? pesalinkNotes;
}

class CompanySettings {
  const CompanySettings({
    required this.ledgerStartMonth,
    required this.dueDay,
    required this.graceDay,
    required this.depositSchedule,
    required this.recordRetentionMonths,
    this.theme = const CompanyTheme(),
    this.pesalinkPhone,
    this.propertyPayments = const {},
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) =>
      CompanySettings(
        ledgerStartMonth: json['ledgerStartMonth'] as String,
        dueDay: json['dueDay'] as int,
        graceDay: json['graceDay'] as int,
        depositSchedule: (json['depositSchedule'] as Map<String, dynamic>).map(
          (bedrooms, amount) => MapEntry(int.parse(bedrooms), amount as int),
        ),
        recordRetentionMonths: json['recordRetentionMonths'] as int,
        theme: json['theme'] != null && json['theme'] is Map<String, dynamic>
            ? CompanyTheme.fromJson(json['theme'] as Map<String, dynamic>)
            : const CompanyTheme(),
        pesalinkPhone: json['pesalinkPhone'] as String?,
        propertyPayments:
            json['propertyPayments'] != null &&
                json['propertyPayments'] is Map<String, dynamic>
            ? (json['propertyPayments'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(
                  k,
                  PropertyPaymentDetail.fromJson(v as Map<String, dynamic>),
                ),
              )
            : const {},
      );

  /// First month on Makazi ('YYYY-MM').
  final String ledgerStartMonth;
  final int dueDay;

  /// Last day of the grace period; a bill is overdue only after it.
  final int graceDay;
  final Map<int, int> depositSchedule;
  final int recordRetentionMonths;

  /// Brand colors & style configured per company.
  final CompanyTheme theme;

  /// Default company-wide PesaLink phone or alias.
  final String? pesalinkPhone;

  /// Per-property payment configuration overrides.
  final Map<String, PropertyPaymentDetail> propertyPayments;
}

/// Makazi subscription. Stored and shown; not enforced or billed yet.
@immutable
class Subscription {
  const Subscription({
    required this.plan,
    required this.status,
    required this.unitLimit,
    required this.staffLimit,
    required this.trialEndsAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    plan: json['plan'] as String,
    status: json['status'] as String,
    unitLimit: json['unitLimit'] as int,
    staffLimit: json['staffLimit'] as int,
    trialEndsAt: json['trialEndsAt'] as String?,
  );

  /// 'starter' | 'growth' | 'pro'
  final String plan;

  /// 'trial' | 'active' | 'past_due' | 'suspended'
  final String status;
  final int unitLimit;
  final int staffLimit;
  final String? trialEndsAt;
}

/// A landlord on the Makazi platform. Every record belongs to one.
@immutable
class Company {
  const Company({
    required this.id,
    required this.slug,
    required this.name,
    required this.kraPin,
    required this.mpesaPaybill,
    required this.bankName,
    required this.bankAccount,
    required this.settings,
    required this.receiptSequence,
    required this.repairTicketSequence,
    required this.subscription,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    final sequences = json['sequences'] as Map<String, dynamic>;
    return Company(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      kraPin: json['kraPin'] as String,
      mpesaPaybill: json['mpesaPaybill'] as String,
      bankName: json['bankName'] as String,
      bankAccount: json['bankAccount'] as String,
      settings: CompanySettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      receiptSequence: sequences['receipt'] as int,
      repairTicketSequence: sequences['repairTicket'] as int,
      subscription: Subscription.fromJson(
        json['subscription'] as Map<String, dynamic>,
      ),
    );
  }

  final String id;
  final String slug;
  final String name;
  final String kraPin;
  final String mpesaPaybill;
  final String bankName;
  final String bankAccount;
  final CompanySettings settings;

  /// Last receipt (RCT-) and repair (MT-) numbers issued by this company.
  final int receiptSequence;
  final int repairTicketSequence;
  final Subscription subscription;
}

/// Rates in force from a month ('YYYY-MM') onwards.
@immutable
class PropertyRates {
  const PropertyRates({
    required this.from,
    required this.waterRate,
    required this.garbageFee,
  });

  factory PropertyRates.fromJson(Map<String, dynamic> json) => PropertyRates(
    from: json['from'] as String,
    waterRate: json['waterRate'] as int,
    garbageFee: json['garbageFee'] as int,
  );

  final String from;
  final int waterRate;
  final int garbageFee;
}

@immutable
class Property {
  const Property({
    required this.id,
    required this.companyId,
    required this.managerId,
    required this.name,
    required this.type,
    required this.address,
    required this.accountPrefix,
    required this.waterRate,
    required this.garbageFee,
    required this.rateHistory,
    this.mpesaPaybill,
    this.bankName,
    this.bankAccount,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    id: json['id'] as String,
    companyId: json['companyId'] as String,
    managerId: json['managerId'] as String,
    name: json['name'] as String,
    type: PropertyType.fromJson(json['type'] as String),
    address: json['address'] as String,
    accountPrefix: json['accountPrefix'] as String,
    waterRate: json['waterRate'] as int,
    garbageFee: json['garbageFee'] as int,
    rateHistory: ((json['rateHistory'] as List<dynamic>?) ?? const [])
        .map((e) => PropertyRates.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    mpesaPaybill: json['mpesaPaybill'] as String?,
    bankName: json['bankName'] as String?,
    bankAccount: json['bankAccount'] as String?,
  );

  final String id;
  final String companyId;

  /// Staff member who manages the property and answers its tenants.
  final String managerId;
  final String name;
  final PropertyType type;
  final String address;
  final String accountPrefix;

  /// Current rates (the latest entry in [rateHistory]).
  final int waterRate;
  final int garbageFee;

  /// Every rate change, oldest first.
  final List<PropertyRates> rateHistory;

  /// Optional dedicated M-Pesa Paybill for this property. If null/empty, uses company default.
  final String? mpesaPaybill;

  /// Optional dedicated bank name for this property. If null/empty, uses company default.
  final String? bankName;

  /// Optional dedicated bank account for this property. If null/empty, uses company default.
  final String? bankAccount;

  /// Rates in force for a bill month; before the first change, the earliest.
  PropertyRates ratesFor(String month) {
    var rates = rateHistory.isEmpty
        ? PropertyRates(
            from: month,
            waterRate: waterRate,
            garbageFee: garbageFee,
          )
        : rateHistory.first;
    for (final r in rateHistory) {
      if (r.from.compareTo(month) <= 0) rates = r;
    }
    return rates;
  }
}

@immutable
class Unit {
  const Unit({
    required this.id,
    required this.propertyId,
    required this.label,
    required this.bedrooms,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json['id'] as String,
    propertyId: json['propertyId'] as String,
    label: json['label'] as String,
    bedrooms: json['bedrooms'] as int,
  );

  final String id;
  final String propertyId;
  final String label;
  final int bedrooms;
}

@immutable
class Tenant {
  const Tenant({
    required this.id,
    required this.companyId,
    required this.name,
    required this.phone,
    required this.email,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'] as String,
    companyId: json['companyId'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
  );

  final String id;
  final String companyId;
  final String name;
  final String phone;
  final String email;

  String get firstName => name.split(' ').first;

  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}

@immutable
class TenancyRenewal {
  const TenancyRenewal({
    required this.leaseId,
    required this.rent,
    required this.start,
    required this.end,
  });

  factory TenancyRenewal.fromJson(Map<String, dynamic> json) => TenancyRenewal(
    leaseId: json['leaseId'] as String,
    rent: json['rent'] as int,
    start: json['start'] as String,
    end: json['end'] as String,
  );

  final String leaseId;
  final int rent;
  final String start;
  final String end;
}

@immutable
class Tenancy {
  const Tenancy({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.rent,
    required this.deposit,
    required this.moveIn,
    required this.moveOut,
    required this.leaseStart,
    required this.leaseEnd,
    required this.openingBalance,
    required this.openingReading,
    required this.renewal,
    this.moveInRent,
    this.moveInGarbage,
  });

  factory Tenancy.fromJson(Map<String, dynamic> json) => Tenancy(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    unitId: json['unitId'] as String,
    rent: json['rent'] as int,
    deposit: json['deposit'] as int,
    moveIn: json['moveIn'] as String,
    moveOut: json['moveOut'] as String?,
    leaseStart: json['leaseStart'] as String,
    leaseEnd: json['leaseEnd'] as String,
    openingBalance: json['openingBalance'] as int,
    openingReading: json['openingReading'] as int?,
    moveInRent: (json['moveInRent'] as num?)?.toInt(),
    moveInGarbage: (json['moveInGarbage'] as num?)?.toInt(),
    renewal: json['renewal'] == null
        ? null
        : TenancyRenewal.fromJson(json['renewal'] as Map<String, dynamic>),
  );

  final String id;
  final String tenantId;
  final String unitId;
  final int rent;
  final int deposit;
  final String moveIn;
  final String? moveOut;
  final String leaseStart;
  final String leaseEnd;
  final int openingBalance;

  /// Water meter at move-in; null for tenancies older than the ledger.
  final int? openingReading;

  /// Rent on the move-in bill, entered by the landlord; null means a full month.
  final int? moveInRent;

  /// Garbage fee override for move-in month; null falls back to property rate.
  final int? moveInGarbage;
  final TenancyRenewal? renewal;

  bool get isActive => moveOut == null;
}

@immutable
class Payment {
  const Payment({
    required this.receiptNumber,
    required this.tenancyId,
    required this.amount,
    required this.date,
    required this.time,
    required this.method,
    required this.reference,
    this.simulated = false,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    receiptNumber: json['receiptNumber'] as String,
    tenancyId: json['tenancyId'] as String,
    amount: json['amount'] as int,
    date: json['date'] as String,
    time: json['time'] as String,
    method: PaymentMethod.fromJson(json['method'] as String),
    reference: json['reference'] as String,
    simulated: json['simulated'] == true,
  );

  final String receiptNumber;
  final String tenancyId;
  final int amount;
  final String date;
  final String time;
  final PaymentMethod method;
  final String reference;

  /// A test payment from M-Pesa test mode: no money moved.
  final bool simulated;
}

/// The facts the engine needs. For the tenant app this is one tenancy's
/// slice; the parity test loads the whole portfolio.
@immutable
class BillingSeed {
  const BillingSeed({
    required this.asOf,
    required this.companies,
    required this.properties,
    required this.units,
    required this.tenants,
    required this.tenancies,
    required this.meterReadings,
    required this.payments,
    required this.staff,
    required this.repairTickets,
    required this.messages,
  });

  factory BillingSeed.fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List<dynamic>)
            .map((e) => parse(e as Map<String, dynamic>))
            .toList(growable: false);

    final readings = (json['meterReadings'] as Map<String, dynamic>).map(
      (unitId, byMonth) => MapEntry(
        unitId,
        (byMonth as Map<String, dynamic>).map(
          (month, value) => MapEntry(month, value as int),
        ),
      ),
    );

    return BillingSeed(
      asOf: json['asOf'] as String,
      companies: listOf('companies', Company.fromJson),
      properties: listOf('properties', Property.fromJson),
      units: listOf('units', Unit.fromJson),
      tenants: listOf('tenants', Tenant.fromJson),
      tenancies: listOf('tenancies', Tenancy.fromJson),
      meterReadings: readings,
      payments: listOf('payments', Payment.fromJson),
      staff: listOf('staff', StaffMember.fromJson),
      repairTickets: listOf('repairTickets', RepairTicketRecord.fromJson),
      messages: listOf('messages', MessageRecord.fromJson),
    );
  }

  /// The demo's "today".
  final String asOf;
  final List<Company> companies;
  final List<Property> properties;
  final List<Unit> units;
  final List<Tenant> tenants;
  final List<Tenancy> tenancies;
  final Map<String, Map<String, int>> meterReadings;
  final List<Payment> payments;
  final List<StaffMember> staff;
  final List<RepairTicketRecord> repairTickets;
  final List<MessageRecord> messages;

  Company companyById(String id) => companies.firstWhere((c) => c.id == id);
}

@immutable
class StaffMember {
  const StaffMember({
    required this.id,
    required this.companyId,
    required this.name,
    required this.role,
    required this.phone,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    companyId: json['companyId'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    phone: json['phone'] as String?,
  );

  final String id;
  final String companyId;
  final String name;

  /// 'owner' | 'manager' | 'caretaker'
  final String role;
  final String? phone;
}

/// A repair request as stored. Wire values match PropAdmin/src/lib/billing.ts
/// (category: plumbing|electrical|carpentry|appliance|security,
/// priority: low|medium|high, status: open|in_progress|resolved).
@immutable
class RepairTicketRecord {
  const RepairTicketRecord({
    required this.id,
    required this.companyId,
    required this.tenancyId,
    required this.unitId,
    required this.category,
    required this.priority,
    required this.status,
    required this.title,
    required this.description,
    required this.hasPhoto,
    required this.createdAt,
    required this.resolvedAt,
    required this.assignedTo,
    required this.resolutionNote,
    this.assignedPhone,
    this.visitAt,
  });

  factory RepairTicketRecord.fromJson(Map<String, dynamic> json) =>
      RepairTicketRecord(
        id: json['id'] as String,
        companyId: json['companyId'] as String,
        tenancyId: json['tenancyId'] as String,
        unitId: json['unitId'] as String,
        category: json['category'] as String,
        priority: json['priority'] as String,
        status: json['status'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        hasPhoto: json['hasPhoto'] as bool,
        createdAt: json['createdAt'] as String,
        resolvedAt: json['resolvedAt'] as String?,
        assignedTo: json['assignedTo'] as String?,
        resolutionNote: json['resolutionNote'] as String?,
        assignedPhone: json['assignedPhone'] as String?,
        visitAt: json['visitAt'] as String?,
      );

  final String id;
  final String companyId;
  final String tenancyId;
  final String unitId;
  final String category;
  final String priority;
  final String status;
  final String title;
  final String description;
  final bool hasPhoto;

  /// ISO date-time with Nairobi offset.
  final String createdAt;
  final String? resolvedAt;
  final String? assignedTo;
  final String? resolutionNote;

  /// Mobile of whoever is fixing it (+2547XXXXXXXX), set by staff.
  final String? assignedPhone;

  /// When they're expected: ISO date-time with Nairobi offset.
  final String? visitAt;

  /// Numeric part of 'MT-1047'.
  int get number => int.parse(id.split('-').last);
}

@immutable
class MessageRecord {
  const MessageRecord({
    required this.id,
    required this.companyId,
    required this.tenancyId,
    required this.sender,
    required this.staffId,
    required this.body,
    required this.sentAt,
    this.readByStaffAt,
  });

  factory MessageRecord.fromJson(Map<String, dynamic> json) => MessageRecord(
    id: json['id'] as String,
    companyId: json['companyId'] as String,
    tenancyId: json['tenancyId'] as String,
    sender: json['sender'] as String,
    staffId: json['staffId'] as String?,
    body: json['body'] as String,
    sentAt: json['sentAt'] as String,
    readByStaffAt: json['readByStaffAt'] as String?,
  );

  final String id;
  final String companyId;
  final String tenancyId;

  /// 'tenant' | 'staff'
  final String sender;
  final String? staffId;
  final String body;

  /// ISO date-time with Nairobi offset.
  final String sentAt;

  final String? readByStaffAt;
}

@immutable
class BillLine {
  const BillLine({required this.kind, required this.amount});

  final BillLineKind kind;
  final int amount;
}

@immutable
class WaterUsage {
  const WaterUsage({
    required this.previousReading,
    required this.currentReading,
    required this.units,
    required this.rate,
  });

  final int previousReading;
  final int currentReading;
  final int units;
  final int rate;

  int get amount => units * rate;
}

@immutable
class MonthlyBill {
  const MonthlyBill({
    required this.tenancyId,
    required this.month,
    required this.kind,
    required this.dueDate,
    required this.graceDate,
    required this.lines,
    required this.water,
    required this.balanceBf,
    required this.amountPaid,
    required this.payments,
  });

  final String tenancyId;

  /// The billing cycle, named after the month it starts in.
  final String month;
  final BillKind kind;
  final String dueDate;

  /// Last day of the grace period.
  final String graceDate;
  final List<BillLine> lines;
  final WaterUsage? water;
  final int balanceBf;
  final int amountPaid;
  final List<Payment> payments;

  int _sumOf(BillLineKind kind) => lines
      .where((line) => line.kind == kind)
      .fold(0, (sum, line) => sum + line.amount);

  int get rent => _sumOf(BillLineKind.rent);
  int get waterAmount => _sumOf(BillLineKind.water);
  int get garbage => _sumOf(BillLineKind.garbage);
  int get deposit => _sumOf(BillLineKind.deposit);
  int get depositApplied => _sumOf(BillLineKind.depositApplied);
  int get depositRefund => _sumOf(BillLineKind.depositRefund);
  int get newCharges => lines.fold(0, (sum, line) => sum + line.amount);
  int get totalDue => balanceBf + newCharges;
  int get outstanding => totalDue - amountPaid;
  String? get datePaid => payments.isEmpty ? null : payments.last.date;

  BillStatus get status {
    if (outstanding < 0) return BillStatus.credit;
    if (outstanding == 0) return BillStatus.paid;
    return amountPaid > 0 ? BillStatus.partial : BillStatus.unpaid;
  }
}
