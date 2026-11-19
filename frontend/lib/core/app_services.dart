import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/api_owner_extras.dart';
import '../services/dormitory_service.dart';
import '../services/local_owner_extras.dart';
import '../services/owner_account_service.dart';
import '../services/owner_extras.dart';
import '../services/verification_service.dart';
import 'network/api_client.dart';
import 'network/token_store.dart';
import '../services/favorite_service.dart';
import '../services/public_dormitory_service.dart';

/// true = ฟีเจอร์ owner ที่ backend ยังไม่มี (amenities, ลบหอ, report รีวิว,
/// โปรไฟล์/รหัสผ่าน, ตั้งค่าแจ้งเตือน ฯลฯ) เก็บในเครื่อง
/// ตั้งเป็น false เมื่อ backend มี endpoint ตามสัญญาแล้ว (ดู ApiOwnerExtras)
const bool kLocalOwnerExtras = false;

/// รวม service ที่ใช้ทั้งแอป สร้างครั้งเดียวตอนเริ่มแอป
/// เพิ่ม service ของแต่ละ feature ที่นี่เมื่อทำ feature นั้น
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

  // admin ใช้ AdminService ที่สร้างเองจาก api ใน AdminHomeScreen

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
