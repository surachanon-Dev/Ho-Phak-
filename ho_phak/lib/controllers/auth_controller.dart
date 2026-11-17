import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthController {
  static final ValueNotifier<AppUser> currentUser = ValueNotifier<AppUser>(
    const AppUser(
      name: 'MFU Student',
      email: 'student@lamduan.mfu.ac.th',
      phone: '081-234-5678',
    ),
  );

  static void updateProfile({String? name, String? phone}) {
    currentUser.value = currentUser.value.copyWith(
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : null,
      phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
    );
  }

  static void updateAvatar(String? url) {
    if (url == null) {
      currentUser.value = currentUser.value.copyWith(clearAvatar: true);
    } else {
      currentUser.value = currentUser.value.copyWith(avatarUrl: url);
    }
  }
}