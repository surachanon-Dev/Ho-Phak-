import 'api_client.dart';
import 'api_owner_extras.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'dormitory_service.dart';
import 'favorite_service.dart';
import 'local_owner_extras.dart';
import 'notification_service.dart';
import 'owner_extras.dart';
import 'public_dormitory_service.dart';
import 'token_store.dart';
import 'verification_service.dart';

/// true = ฟีเจอร์ owner ที่ backend ยังไม่มี (amenities, ลบหอ, report รีวิว,
/// โปรไฟล์/รหัสผ่าน, ตั้งค่าแจ้งเตือน ฯลฯ) เก็บในเครื่อง
/// ตั้งเป็น false เมื่อ backend มี endpoint ตามสัญญาแล้ว (ดู ApiOwnerExtras)
const bool kLocalOwnerExtras = true;

/// รวม service ทั้งหมดไว้ที่เดียว สร้างครั้งเดียวตอนเริ่มแอป
class AppServices {
  AppServices() {
    tokens = TokenStore();
    api = ApiClient(tokenProvider: () => tokens.token);
    auth = AuthService(api, tokens);
    extras = kLocalOwnerExtras
        ? LocalOwnerExtras(userId: () => auth.userId)
        : ApiOwnerExtras(api);
    dormitories = DormitoryService(api, extras);
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
  late final ChatService chats;
  late final VerificationService verification;
  late final NotificationService notifications;
  late final PublicDormitoryService publicDorms;
  late final FavoriteService favorites;
}
