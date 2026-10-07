import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../billing/billing_models.dart';

/// Thrown when the signed-in account has no tenancy the app may show (not
/// onboarded yet, or past the record-retention period after move-out).
class NoTenancyFound implements Exception {
  const NoTenancyFound();
}

/// A Postgres timestamptz as Nairobi time, 'YYYY-MM-DDTHH:MM:SS+03:00' like
/// the seed, so the app shows the same clock time as the admin.
String nairobiIso(String timestamptz) {
  final local = DateTime.parse(
    timestamptz,
  ).toUtc().add(const Duration(hours: 3)).toIso8601String().substring(0, 19);
  return '$local+03:00';
}

/// Reads the signed-in tenant's own slice of the database and writes the few
/// things a tenant may write (repair requests, messages). Every query runs as
/// the tenant, so row-level security decides what comes back. Payments are
/// never written from the app: they come from the manager or M-Pesa.
class SupabaseBillingRepository {
  SupabaseBillingRepository({this.client});

  /// For tests; the app uses the initialised Supabase client.
  final SupabaseClient? client;

  SupabaseClient get _sb => client ?? Supabase.instance.client;

  /// The tenant's [BillingSeed]: one company, property, unit and tenancy.
  /// Throws [NoTenancyFound] when there is nothing to show, and the
  /// underlying error when the database can't be reached.
  Future<BillingSeed> fetchTenantSeed() async {
    return _fetchTenantSeedInternal().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Connection timed out'),
    );
  }

  Future<BillingSeed> _fetchTenantSeedInternal() async {
    final sb = _sb;
    final userId = sb.auth.currentUser?.id;
    if (userId == null) throw const NoTenancyFound();

    // Fetch tenant records and embedded tenancies in a single round-trip.
    final tenantRows = _rows(
      await sb
          .from('tenants')
          .select('*, tenancies(*)')
          .eq('auth_user_id', userId),
    );
    if (tenantRows.isEmpty) throw const NoTenancyFound();

    var tenancyRows = <Map<String, dynamic>>[];
    for (final t in tenantRows) {
      final list = t['tenancies'];
      if (list is List) {
        for (final row in list) {
          if (row is Map) tenancyRows.add(row.cast<String, dynamic>());
        }
      }
    }

    if (tenancyRows.isEmpty) {
      tenancyRows = _rows(
        await sb.from('tenancies').select().inFilter('tenant_id', [
          for (final t in tenantRows) t['id'],
        ]),
      );
    }
    if (tenancyRows.isEmpty) throw const NoTenancyFound();

    // The current tenancy, else the most recent former one.
    tenancyRows.sort((a, b) {
      final aCurrent = a['move_out'] == null ? 1 : 0;
      final bCurrent = b['move_out'] == null ? 1 : 0;
      if (aCurrent != bCurrent) return bCurrent - aCurrent;
      return (b['move_in'] as String).compareTo(a['move_in'] as String);
    });
    final tenancyRow = tenancyRows.first;
    final companyId = tenancyRow['company_id'] as String;
    final tenancyId = tenancyRow['id'] as String;
    final unitId = tenancyRow['unit_id'] as String;
    final tenantRow = tenantRows.firstWhere(
      (t) => t['id'] == tenancyRow['tenant_id'] && t['company_id'] == companyId,
    );

    // Fetch company, unit (with embedded property & staff), payments, meter readings,
    // repair tickets, and messages concurrently.
    final results = await Future.wait<dynamic>([
      sb.from('companies').select().eq('id', companyId).single(),
      sb
          .from('units')
          .select('*, properties(*, staff(*))')
          .eq('company_id', companyId)
          .eq('id', unitId)
          .single(),
      sb
          .from('payments')
          .select()
          .eq('company_id', companyId)
          .eq('tenancy_id', tenancyId),
      sb
          .from('meter_readings')
          .select()
          .eq('company_id', companyId)
          .eq('unit_id', unitId),
      sb
          .from('repair_tickets')
          .select()
          .eq('company_id', companyId)
          .eq('tenancy_id', tenancyId),
      sb
          .from('messages')
          .select()
          .eq('company_id', companyId)
          .eq('tenancy_id', tenancyId),
    ]);

    final companyRow = (results[0] as Map).cast<String, dynamic>();
    final unitData = (results[1] as Map).cast<String, dynamic>();
    final paymentRows = _rows(results[2]);
    final meterRows = _rows(results[3]);
    final ticketRows = _rows(results[4]);
    final messageRows = _rows(results[5]);

    Map<String, dynamic> propertyRow;
    List<Map<String, dynamic>> staffRows = [];

    if (unitData['properties'] is Map) {
      propertyRow = (unitData['properties'] as Map).cast<String, dynamic>();
      if (propertyRow['staff'] is Map) {
        staffRows = [(propertyRow['staff'] as Map).cast<String, dynamic>()];
      }
    } else {
      propertyRow =
          (await sb
                      .from('properties')
                      .select()
                      .eq('company_id', companyId)
                      .eq('id', unitData['property_id'] as String)
                      .single()
                  as Map)
              .cast<String, dynamic>();
    }

    if (staffRows.isEmpty && propertyRow['manager_id'] != null) {
      staffRows = _rows(
        await sb
            .from('staff')
            .select()
            .eq('company_id', companyId)
            .eq('id', propertyRow['manager_id'] as String),
      );
    }

    final meterReadings = <String, Map<String, int>>{unitId: {}};
    for (final row in meterRows) {
      meterReadings[unitId]![row['month'] as String] = (row['value'] as num)
          .toInt();
    }

    final asOf = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 3))
        .toIso8601String()
        .substring(0, 10);

    return BillingSeed(
      asOf: asOf,
      companies: [_company(companyRow)],
      properties: [_property(propertyRow)],
      units: [
        Unit(
          id: unitData['id'] as String,
          propertyId: unitData['property_id'] as String,
          label: unitData['label'] as String,
          bedrooms: (unitData['bedrooms'] as num).toInt(),
        ),
      ],
      tenants: [
        Tenant(
          id: tenantRow['id'] as String,
          companyId: tenantRow['company_id'] as String,
          name: tenantRow['name'] as String,
          phone: tenantRow['phone'] as String,
          email: tenantRow['email'] as String? ?? '',
        ),
      ],
      tenancies: [_tenancy(tenancyRow)],
      meterReadings: meterReadings,
      payments: [for (final row in paymentRows) _payment(row)],
      staff: [
        for (final row in staffRows)
          StaffMember(
            id: row['id'] as String,
            companyId: row['company_id'] as String,
            name: row['name'] as String,
            role: row['role'] as String,
            phone: row['phone'] as String?,
          ),
      ],
      repairTickets: [for (final row in ticketRows) ticketFromRow(row)],
      messages: [for (final row in messageRows) messageFromRow(row)],
    );
  }

  /// Files a repair request; the database numbers it (MT-NNNN). Throws if
  /// it wasn't saved.
  Future<RepairTicketRecord> submitRepairTicket({
    required String companyId,
    required String tenancyId,
    required String unitId,
    required String category,
    required String title,
    required String description,
    required bool hasPhoto,
  }) async {
    final row = await _sb
        .from('repair_tickets')
        .insert({
          'company_id': companyId,
          'tenancy_id': tenancyId,
          'unit_id': unitId,
          'category': category,
          'title': title,
          'description': description,
          'has_photo': hasPhoto,
        })
        .select()
        .single();
    return ticketFromRow(row);
  }

  /// Sends a message to the property manager. Throws if it wasn't saved.
  Future<MessageRecord> sendMessage({
    required String companyId,
    required String tenancyId,
    required String body,
  }) async {
    final row = await _sb
        .from('messages')
        .insert({
          'company_id': companyId,
          'tenancy_id': tenancyId,
          'sender': 'tenant',
          'body': body,
        })
        .select()
        .single();
    return messageFromRow(row);
  }

  /// Listens for the admin's "something changed" nudges. Payloads carry no
  /// data (PropAdmin/src/lib/realtime.ts); [onChanged] should refetch.
  TenantRealtime subscribe({
    required String companyId,
    required String tenancyId,
    required void Function() onChanged,
    required void Function(bool isTyping) onTyping,
  }) {
    final sb = _sb;
    final company = sb
        .channel('makazi:events:$companyId')
        .onBroadcast(event: 'data_updated', callback: (_) => onChanged())
        .subscribe();
    final tenancy = sb
        .channel('makazi:tenancy:$tenancyId')
        .onBroadcast(event: 'data_updated', callback: (_) => onChanged())
        .onBroadcast(event: 'message_sent', callback: (_) => onChanged())
        .onBroadcast(
          event: 'typing',
          callback: (payload) => onTyping(payload['isTyping'] == true),
        )
        .subscribe();
    return TenantRealtime._(sb, [company, tenancy]);
  }

  static List<Map<String, dynamic>> _rows(Object? result) => [
    for (final row in result as List<dynamic>) (row as Map).cast(),
  ];

  static Company _company(Map<String, dynamic> row) {
    final sequences = (row['sequences'] as Map<String, dynamic>?) ?? {};
    return Company(
      id: row['id'] as String,
      slug: row['slug'] as String,
      name: row['name'] as String,
      kraPin: row['kra_pin'] as String? ?? '',
      mpesaPaybill: row['mpesa_paybill'] as String? ?? '',
      bankName: row['bank_name'] as String? ?? '',
      bankAccount: row['bank_account'] as String? ?? '',
      settings: CompanySettings.fromJson(
        row['settings'] as Map<String, dynamic>,
      ),
      receiptSequence: (sequences['receipt'] as num?)?.toInt() ?? 0,
      repairTicketSequence: (sequences['repairTicket'] as num?)?.toInt() ?? 0,
      subscription: Subscription.fromJson(
        row['subscription'] as Map<String, dynamic>,
      ),
    );
  }

  static Property _property(Map<String, dynamic> row) => Property(
    id: row['id'] as String,
    companyId: row['company_id'] as String,
    managerId: row['manager_id'] as String,
    name: row['name'] as String,
    type: PropertyType.fromJson(row['type'] as String),
    address: row['address'] as String? ?? '',
    accountPrefix: row['account_prefix'] as String,
    waterRate: (row['water_rate'] as num).toInt(),
    garbageFee: (row['garbage_fee'] as num).toInt(),
    rateHistory: [
      for (final r in (row['rate_history'] as List<dynamic>?) ?? const [])
        PropertyRates.fromJson(r as Map<String, dynamic>),
    ],
  );

  static Tenancy _tenancy(Map<String, dynamic> row) => Tenancy(
    id: row['id'] as String,
    tenantId: row['tenant_id'] as String,
    unitId: row['unit_id'] as String,
    rent: (row['rent'] as num).toInt(),
    deposit: (row['deposit'] as num).toInt(),
    moveIn: row['move_in'] as String,
    moveOut: row['move_out'] as String?,
    leaseStart: row['lease_start'] as String,
    leaseEnd: row['lease_end'] as String,
    openingBalance: (row['opening_balance'] as num).toInt(),
    openingReading: (row['opening_reading'] as num?)?.toInt(),
    renewal: row['renewal'] != null
        ? TenancyRenewal.fromJson(row['renewal'] as Map<String, dynamic>)
        : null,
  );

  static Payment _payment(Map<String, dynamic> row) => Payment(
    receiptNumber: row['receipt_number'] as String,
    tenancyId: row['tenancy_id'] as String,
    amount: (row['amount'] as num).toInt(),
    date: row['date'] as String,
    time: (row['time'] as String).substring(0, 5),
    method: PaymentMethod.fromJson(row['method'] as String),
    reference: row['reference'] as String,
  );

  static RepairTicketRecord ticketFromRow(Map<String, dynamic> row) =>
      RepairTicketRecord(
        id: row['id'] as String,
        companyId: row['company_id'] as String,
        tenancyId: row['tenancy_id'] as String,
        unitId: row['unit_id'] as String,
        category: row['category'] as String,
        priority: row['priority'] as String? ?? 'medium',
        status: row['status'] as String? ?? 'open',
        title: row['title'] as String,
        description: row['description'] as String? ?? '',
        hasPhoto: row['has_photo'] as bool? ?? false,
        createdAt: nairobiIso(row['created_at'] as String),
        resolvedAt: row['resolved_at'] == null
            ? null
            : nairobiIso(row['resolved_at'] as String),
        assignedTo: row['assigned_to'] as String?,
        resolutionNote: row['resolution_note'] as String?,
      );

  static MessageRecord messageFromRow(Map<String, dynamic> row) =>
      MessageRecord(
        id: row['id'] as String,
        companyId: row['company_id'] as String,
        tenancyId: row['tenancy_id'] as String,
        sender: row['sender'] as String,
        staffId: row['staff_id'] as String?,
        body: row['body'] as String,
        sentAt: nairobiIso(row['sent_at'] as String),
      );
}

/// The two realtime channels a signed-in tenant listens on.
class TenantRealtime {
  TenantRealtime._(this._sb, this._channels);

  final SupabaseClient _sb;
  final List<RealtimeChannel> _channels;

  Future<void> dispose() async {
    for (final channel in _channels) {
      await _sb.removeChannel(channel);
    }
  }
}
