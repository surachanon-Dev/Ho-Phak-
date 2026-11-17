import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/owner/services/api_owner_extras.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/features/chat/services/chat_service.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/student/services/favorite_service.dart';
import 'package:hopak_frontend/features/owner/services/local_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/owner_account_service.dart';
import 'package:hopak_frontend/features/notifications/services/notification_service.dart';
import 'package:hopak_frontend/features/owner/services/owner_extras.dart';
import 'package:hopak_frontend/features/student/services/public_dormitory_service.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:hopak_frontend/features/owner/services/verification_service.dart';

/// true = ฟีเจอร์ owner ที่ backend ยังไม่มี (amenities, ลบหอ, report รีวิว,
/// โปรไฟล์/รหัสผ่าน, ตั้งค่าแจ้งเตือน ฯลฯ) เก็บในเครื่อง
/// ตั้งเป็น false เมื่อ backend มี endpoint ตามสัญญาแล้ว (ดู ApiOwnerExtras)
const bool kLocalOwnerExtras = false;

/// รวม service ทั้งหมดไว้ที่เดียว สร้างครั้งเดียวตอนเริ่มแอป
class AppServices {
  /// [localOwnerExtras] เว้นว่างไว้ = ใช้ค่า kLocalOwnerExtras (เทสต์ส่ง true เพื่อไม่เรียกเครือข่าย)
  AppServices({bool? localOwnerExtras}) {
    tokens = TokenStore();
    api = ApiClient(tokenProvider: () => tokens.token);
    auth = AuthService(api, tokens);
    extras = (localOwnerExtras ?? kLocalOwnerExtras)
        ? LocalOwnerExtras(userId: () => auth.userId)
        : ApiOwnerExtras(api);
    dormitories = DormitoryService(api, extras);
    account = OwnerAccountService(extras);
    chats = ChatService(api);
    verification = VerificationService(api);
    notifications = NotificationService(api);
    publicDorms = PublicDormitoryService(api);
    favorites = FavoriteService(api);
  }

  // ใช้ใน AdminHomeScreen ผ่าน AdminService ที่สร้างเองจาก api

  late final TokenStore tokens;
  late final ApiClient api;
  late final AuthService auth;
  late final OwnerExtras extras;
  late final DormitoryService dormitories;
  late final OwnerAccountService account;
  late final ChatService chats;
  late final VerificationService verification;
  late final NotificationService notifications;
  late final PublicDormitoryService publicDorms;
  late final FavoriteService favorites;
}
