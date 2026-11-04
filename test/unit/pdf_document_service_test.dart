import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prop_mgt_app/core/services/pdf_document_service.dart';
import 'package:prop_mgt_app/features/billing/presentation/state/tenant_account_providers.dart';

void main() {
  setUp(() {
    PdfDocumentService.useGoogleFonts = false;
  });

  group('PdfDocumentService', () {
    test('generateReceiptPdf generates valid PDF bytes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final account = container.read(tenantAccountProvider);
      final receipt = account.receipts.first;

      final pdfBytes = await PdfDocumentService.generateReceiptPdf(
        receipt: receipt,
        company: account.company,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF documents start with '%PDF-'
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('generateStatementPdf generates valid PDF bytes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final account = container.read(tenantAccountProvider);

      final pdfBytes = await PdfDocumentService.generateStatementPdf(
        account: account,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test(
      'downloadReceipt calls sharePdf with correct filename and bytes',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final account = container.read(tenantAccountProvider);
        final receipt = account.receipts.first;

        String? capturedFilename;
        Uint8List? capturedBytes;

        PdfDocumentService.sharePdf =
            ({required Uint8List bytes, required String filename}) async {
              capturedFilename = filename;
              capturedBytes = bytes;
              return true;
            };

        await PdfDocumentService.downloadReceipt(
          receipt: receipt,
          company: account.company,
        );

        expect(
          capturedFilename,
          equals('Receipt-${receipt.receiptNumber}.pdf'),
        );
        expect(capturedBytes, isNotNull);
        expect(capturedBytes!.isNotEmpty, isTrue);
      },
    );

    test(
      'downloadStatement calls sharePdf with correct filename and bytes',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final account = container.read(tenantAccountProvider);

        String? capturedFilename;
        Uint8List? capturedBytes;

        PdfDocumentService.sharePdf =
            ({required Uint8List bytes, required String filename}) async {
              capturedFilename = filename;
              capturedBytes = bytes;
              return true;
            };

        await PdfDocumentService.downloadStatement(account: account);

        expect(
          capturedFilename,
          equals('Statement-${account.tenant.name.replaceAll(' ', '_')}.pdf'),
        );
        expect(capturedBytes, isNotNull);
        expect(capturedBytes!.isNotEmpty, isTrue);
      },
    );
  });
}
