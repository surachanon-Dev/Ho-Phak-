import 'network/api_client.dart';
import '../features/owner/services/api_owner_extras.dart';
import '../features/auth/services/auth_service.dart';
import '../features/chat/services/chat_service.dart';
import '../features/owner/controllers/dormitory_controller.dart';
import '../features/student/services/favorite_service.dart';
import '../features/owner/services/local_owner_extras.dart';
import '../features/owner/controllers/owner_account_controller.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/owner/services/owner_extras.dart';
import '../features/student/services/public_dormitory_service.dart';
import 'network/token_store.dart';
import '../features/owner/controllers/verification_controller.dart';

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
    dormitories = DormitoryController(api, extras);
    account = OwnerAccountController(extras);
    chats = ChatService(api);
    verification = VerificationController(api);
    notifications = NotificationService(api);
    publicDorms = PublicDormitoryService(api);
    favorites = FavoriteService(api);
  }

  // ใช้ใน AdminHomeScreen ผ่าน AdminService ที่สร้างเองจาก api

  late final TokenStore tokens;
  late final ApiClient api;
  late final AuthService auth;
  late final OwnerExtras extras;
  late final DormitoryController dormitories;
  late final OwnerAccountController account;
  late final ChatService chats;
  late final VerificationController verification;
  late final NotificationService notifications;
  late final PublicDormitoryService publicDorms;
  late final FavoriteService favorites;
}
