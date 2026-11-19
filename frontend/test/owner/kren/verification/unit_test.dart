// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// unit test: VerificationScreenController และ DocumentCheck (ตรวจไฟล์เอกสารยืนยันตัวตน)
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/verification.dart';
import 'package:hopak_frontend/modules/owner/verification/controller/verification_screen_controller.dart';
import 'package:hopak_frontend/services/verification_service.dart';
import 'package:mocktail/mocktail.dart';

class MockVerificationService extends Mock implements VerificationService {}

UploadFile file([String name = 'id.pdf', int size = 1024]) =>
    UploadFile(bytes: Uint8List(size), filename: name);

void main() {
  late MockVerificationService service;
  late VerificationScreenController controller;

  setUpAll(() => registerFallbackValue(file()));

  setUp(() {
    service = MockVerificationService();
    controller = VerificationScreenController(service);
    when(() => service.current()).thenAnswer((_) async => null);
  });

  group('DocumentCheck', () {
    test('1. accepts pdf, jpg, jpeg and png in any letter case', () {
      for (final name in ['a.pdf', 'a.JPG', 'a.jpeg', 'a.PNG']) {
        expect(DocumentCheck.validate(filename: name, sizeBytes: 100), isNull);
      }
    });

    test('2. rejects other file types and files without an extension', () {
      expect(
        DocumentCheck.validate(filename: 'a.exe', sizeBytes: 100),
        'Choose a PDF, JPG or PNG file',
      );
      expect(
        DocumentCheck.validate(filename: 'scan', sizeBytes: 100),
        'Choose a PDF, JPG or PNG file',
      );
    });

    test('3. rejects a file over 10 MB but allows exactly 10 MB', () {
      const max = 10 * 1024 * 1024;

      expect(DocumentCheck.validate(filename: 'a.pdf', sizeBytes: max), isNull);
      expect(
        DocumentCheck.validate(filename: 'a.pdf', sizeBytes: max + 1),
        'File is larger than 10 MB',
      );
    });
  });

  group('VerificationScreenController', () {
    test('4. no document yet means the owner can submit', () async {
      expect(await controller.load(), isTrue);

      expect(controller.current, isNull);
      expect(controller.canSubmit, isTrue);
      expect(controller.loading, isFalse);
    });

    test('5. a pending document blocks submitting again', () async {
      when(() => service.current()).thenAnswer(
        (_) async => Verification(status: VerificationStatus.pending),
      );

      await controller.load();

      expect(controller.canSubmit, isFalse);
    });

    test('6. a rejected document can be sent again', () async {
      when(() => service.current()).thenAnswer(
        (_) async => Verification(
          status: VerificationStatus.rejected,
          reason: 'Photo is blurry',
        ),
      );

      await controller.load();

      expect(controller.canSubmit, isTrue);
      expect(controller.current!.reason, 'Photo is blurry');
    });

    test('7. load that fails keeps the error', () async {
      when(() => service.current()).thenThrow(ApiException(500, 'down'));

      expect(await controller.load(), isFalse);

      expect(controller.error, isA<ApiException>());
    });

    test('8. pick keeps a valid file', () {
      expect(controller.pick(file('id.pdf')), isTrue);

      expect(controller.picked!.filename, 'id.pdf');
      expect(controller.pickError, isNull);
    });

    test('9. pick of a bad file clears the old choice and shows why', () {
      controller.pick(file('id.pdf'));

      expect(controller.pick(file('virus.exe')), isFalse);

      expect(controller.picked, isNull);
      expect(controller.pickError, 'Choose a PDF, JPG or PNG file');
    });

    test('10. submit without a file does nothing', () async {
      await controller.load();

      expect(await controller.submit(), isFalse);

      verifyNever(() => service.submit(any()));
    });

    test(
      '11. submit sends the file, clears it and reloads the status',
      () async {
        when(() => service.submit(any())).thenAnswer((_) async {});
        await controller.load();
        controller.pick(file('id.pdf'));
        when(() => service.current()).thenAnswer(
          (_) async => Verification(status: VerificationStatus.pending),
        );

        expect(await controller.submit(), isTrue);

        verify(() => service.submit(any())).called(1);
        expect(controller.picked, isNull);
        expect(controller.current!.status, VerificationStatus.pending);
        expect(controller.saving, isFalse);
      },
    );

    test('12. submit is blocked while a document is pending', () async {
      when(() => service.current()).thenAnswer(
        (_) async => Verification(status: VerificationStatus.pending),
      );
      await controller.load();
      controller.pick(file('id.pdf'));

      expect(await controller.submit(), isFalse);

      verifyNever(() => service.submit(any()));
    });

    test('13. submit that fails keeps the file and the error', () async {
      when(() => service.submit(any()))
          .thenThrow(ApiException(413, 'Too large'));
      await controller.load();
      controller.pick(file('id.pdf'));

      expect(await controller.submit(), isFalse);

      expect(controller.error, isA<ApiException>());
      expect(controller.picked, isNotNull);
      expect(controller.saving, isFalse);
    });

    test('14. Verification reads the backend JSON', () {
      final v = Verification.fromJson({
        'status': 'rejected',
        'document_url': '/uploads/doc.pdf',
        'rejection_reason': 'Photo is blurry',
      });

      expect(v.status, VerificationStatus.rejected);
      expect(v.documentUrl, '/uploads/doc.pdf');
      expect(v.reason, 'Photo is blurry');
      expect(VerificationStatus.label(VerificationStatus.approved), 'Verified');
    });
  });
}
