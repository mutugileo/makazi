import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/billing/billing_models.dart';
import 'package:prop_mgt_app/core/config/supabase_config.dart';
import 'package:prop_mgt_app/core/data/data_mode.dart';
import 'package:prop_mgt_app/core/data/supabase_billing_repository.dart';
import 'package:prop_mgt_app/features/auth/data/auth_repository.dart';
import 'package:prop_mgt_app/features/auth/data/supabase_auth_repository.dart';
import 'package:prop_mgt_app/features/auth/domain/auth_models.dart';
import 'package:prop_mgt_app/features/auth/presentation/state/auth_providers.dart';

void main() {
  group('SupabaseConfig', () {
    test('has the project URL and publishable key', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.anonKey, startsWith('sb_publishable_'));
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test('no service-role key is compiled into the app', () {
      // The service role bypasses row-level security; it lives only on
      // servers (PropAdmin/.env), never in lib/.
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final source = file.readAsStringSync();
        expect(
          source.contains('service_role') ||
              source.contains('serviceRole') ||
              RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.').hasMatch(source),
          isFalse,
          reason: '${file.path} looks like it holds a service-role key',
        );
      }
    });
  });

  group('Data mode', () {
    test('tests and the demo build use seed data and demo sign-in', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(liveDataProvider), isFalse);
      expect(container.read(authRepositoryProvider), isA<DemoAuthRepository>());
    });
  });

  group('SupabaseBillingRepository row mapping', () {
    test('timestamps are shown in Nairobi time, like the seed', () {
      expect(
        nairobiIso('2026-10-07T06:40:00+00:00'),
        '2026-10-07T09:40:00+03:00',
      );
      expect(
        nairobiIso('2026-10-07T22:15:30.123456+00:00'),
        '2026-10-08T01:15:30+03:00',
      );
    });

    test('maps a repair ticket row', () {
      final ticket = SupabaseBillingRepository.ticketFromRow({
        'id': 'MT-1048',
        'company_id': 'harborridge',
        'tenancy_id': 'L-1',
        'unit_id': 'kh-a03',
        'category': 'plumbing',
        'priority': 'medium',
        'status': 'open',
        'title': 'Leak',
        'description': 'Under the sink',
        'has_photo': false,
        'created_at': '2026-10-07T06:40:00+00:00',
        'resolved_at': null,
        'assigned_to': null,
        'resolution_note': null,
      });
      expect(ticket.id, 'MT-1048');
      expect(ticket.createdAt, '2026-10-07T09:40:00+03:00');
      expect(ticket.resolvedAt, isNull);
    });

    test('maps a message row', () {
      final message = SupabaseBillingRepository.messageFromRow({
        'id': 'a1',
        'company_id': 'harborridge',
        'tenancy_id': 'L-1',
        'sender': 'staff',
        'staff_id': 's-owner',
        'body': 'Hello',
        'sent_at': '2026-10-07T06:12:00+00:00',
      });
      expect(message.sentAt.substring(11, 16), '09:12');
    });
  });

  group('SupabaseAuthRepository', () {
    test('rejects invalid phone numbers before calling the server', () async {
      final repo = SupabaseAuthRepository();
      final outcome = await repo.signIn(
        phone: 'invalid-number',
        password: 'password',
      );
      expect(outcome, SignInOutcome.invalidCredentials);
    });
  });

  group('Model parsing parity', () {
    test('parses snake_case company row into domain model', () {
      final companyRow = {
        'id': 'harborridge',
        'slug': 'harborridge',
        'name': 'HarborRidge Limited',
        'kra_pin': 'P051234567X',
        'mpesa_paybill': '522533',
        'bank_name': 'NCBA Bank',
        'bank_account': '1004558231',
        'settings': {
          'ledgerStartMonth': '2026-05',
          'dueDay': 5,
          'graceDay': 20,
          'depositSchedule': {'1': 25000, '2': 30000},
          'recordRetentionMonths': 6,
        },
        'sequences': {'receipt': 379, 'repairTicket': 1047},
        'subscription': {
          'plan': 'growth',
          'status': 'active',
          'unitLimit': 100,
          'staffLimit': 10,
          'trialEndsAt': null,
        },
      };

      final company = Company(
        id: companyRow['id'] as String,
        slug: companyRow['slug'] as String,
        name: companyRow['name'] as String,
        kraPin: companyRow['kra_pin'] as String,
        mpesaPaybill: companyRow['mpesa_paybill'] as String,
        bankName: companyRow['bank_name'] as String,
        bankAccount: companyRow['bank_account'] as String,
        settings: CompanySettings.fromJson(
          companyRow['settings'] as Map<String, dynamic>,
        ),
        receiptSequence:
            (companyRow['sequences'] as Map<String, dynamic>)['receipt'] as int,
        repairTicketSequence:
            (companyRow['sequences'] as Map<String, dynamic>)['repairTicket']
                as int,
        subscription: Subscription.fromJson(
          companyRow['subscription'] as Map<String, dynamic>,
        ),
      );

      expect(company.id, 'harborridge');
      expect(company.name, 'HarborRidge Limited');
      expect(company.receiptSequence, 379);
    });
  });
}
