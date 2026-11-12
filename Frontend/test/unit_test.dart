import 'package:flutter_test/flutter_test.dart';
import 'package:hophak_frontend/core/api_client.dart';
import 'package:hophak_frontend/mock/mock_db.dart';
import 'package:hophak_frontend/services/admin_service.dart';
import 'package:hophak_frontend/services/auth_service.dart';
import 'package:hophak_frontend/services/dorm_service.dart';
import 'package:hophak_frontend/services/owner_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Business rules of the mock (the same rules the backend must enforce)
void main() {
  final db = MockDb.instance;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('auth', () {
    test('login with username or phone', () async {
      final a = AuthService();
      expect((await a.login('Frame', 'Pass@1234')).role, 'student');
      final u = db.userById(1)!;
      expect((await a.login(u['phone'] as String, 'Pass@1234')).id, 1);
    });

    test('wrong password is rejected', () async {
      final a = AuthService();
      await expectLater(a.login('Frame', 'nope'), throwsA(isA<ApiException>()));
    });

    test('register validates phone and uniqueness', () async {
      final a = AuthService();
      await expectLater(a.register(phone: '123', password: 'Pass@1234', role: 'student'), throwsA(isA<ApiException>()));
      await expectLater(a.register(username: 'Frame', phone: '0899999999', password: 'Pass@1234', role: 'student'),
          throwsA(isA<ApiException>()));
    });
  });

  group('forgot password (phone + OTP)', () {
    test('unknown phone is rejected', () async {
      await expectLater(AuthService().requestPasswordReset('0999999999'), throwsA(isA<ApiException>()));
    });

    test('wrong OTP is rejected; correct OTP lets the user set a new password', () async {
      final a = AuthService();
      const phone = '0629546685'; // Frame
      final code = await a.requestPasswordReset(phone);
      expect(code.length, 6);
      final wrong = code == '000000' ? '111111' : '000000';
      await expectLater(a.verifyResetOtp(phone, wrong), throwsA(isA<ApiException>()));
      final token = await a.verifyResetOtp(phone, code);
      await expectLater(a.resetPassword(phone, token, 'short'), throwsA(isA<ApiException>()));
      await a.resetPassword(phone, token, 'NewPass@99');
      expect((await a.login('Frame', 'NewPass@99')).id, 3);
      // put the demo password back for the other tests
      final code2 = await a.requestPasswordReset(phone);
      await a.resetPassword(phone, await a.verifyResetOtp(phone, code2), 'Pass@1234');
    });
  });

  group('students', () {
    test('only published dorms are visible', () async {
      db.currentUserId = 3;
      final list = await DormService().search(const DormFilter());
      expect(list, isNotEmpty);
      expect(list.every((d) => d.status == 'published'), isTrue);
    });
  });

  group('students – reviews', () {
    test('a new review is shown right away (no moderation)', () async {
      db.currentUserId = 3; // Frame – has not reviewed dorm 3 yet
      final s = DormService();
      await s.submitReview(3, 4, 'ดีมาก');
      final reviews = await s.reviews(3);
      expect(reviews.any((r) => r.userId == 3 && r.status == 'published'), isTrue);
    });
  });

  group('owners', () {
    DormForm newForm() => DormForm()
      ..name = 'หอใหม่'
      ..pricePerMonth = 3000
      ..latitude = 19.88
      ..longitude = 99.83
      ..images = ['assets/images/dorm-1-exterior.jpg']
      ..ownershipDocument = 'assets/images/demo-ownership.jpg';

    test('adding a dorm needs photos and an ownership document', () async {
      db.currentUserId = 2; // Big
      final s = OwnerService();
      await expectLater(s.create(newForm()..images = []), throwsA(isA<ApiException>()));
      await expectLater(s.create(newForm()..ownershipDocument = null), throwsA(isA<ApiException>()));
      final d = await s.create(newForm());
      expect(d.status, 'pending');
      expect(d.ownershipDocumentUrl, 'assets/images/demo-ownership.jpg');
    });

    test('owner sees only own dorms; edit of a published dorm is saved right away', () async {
      db.currentUserId = 2; // Big
      final s = OwnerService();
      final mine = await s.myDorms();
      expect(mine.every((d) => d.ownerId == 2), isTrue);
      final pub = mine.firstWhere((d) => d.status == 'published');
      final f = DormForm.fromDorm(pub)..pricePerMonth = pub.pricePerMonth + 100;
      await s.update(pub.id, f);
      final after = await s.get(pub.id);
      expect(after.status, 'published');
      expect(after.pricePerMonth, pub.pricePerMonth + 100);
    });

    test('editing a rejected dorm sends it back to pending', () async {
      db.currentUserId = 2;
      final s = OwnerService();
      final rej = (await s.myDorms()).firstWhere((d) => d.status == 'rejected');
      await s.update(rej.id, DormForm.fromDorm(rej));
      expect((await s.get(rej.id)).status, 'pending');
    });

    test('suspended dorm cannot be edited', () async {
      db.currentUserId = 2;
      final s = OwnerService();
      final susp = (await s.myDorms()).firstWhere((d) => d.status == 'suspended');
      await expectLater(s.update(susp.id, DormForm.fromDorm(susp)), throwsA(isA<ApiException>()));
    });
  });

  group('admin', () {
    test('reject needs a reason, approve publishes and logs', () async {
      db.currentUserId = 10;
      final a = AdminService();
      final pending = (await a.dorms(status: 'pending')).first;
      await expectLater(a.rejectDorm(pending.id, '  '), throwsA(isA<ApiException>()));
      final logsBefore = db.adminLogs.length;
      await a.approveDorm(pending.id);
      expect((await a.dorm(pending.id)).status, 'published');
      expect(db.adminLogs.length, logsBefore + 1);
    });

    test('admin can list all reviews (read-only)', () async {
      db.currentUserId = 10;
      final list = await AdminService().reviews();
      expect(list.length, db.reviews.length);
    });

    test('admins cannot be suspended; non-admin role is blocked', () async {
      db.currentUserId = 10;
      await expectLater(AdminService().suspendUser(10, 'x'), throwsA(isA<ApiException>()));
      db.currentUserId = 3;
      await expectLater(AdminService().stats(), throwsA(isA<ApiException>()));
    });
  });
}
