import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Controller (MVC): logged-in user + auth actions for the views
class AuthController extends ChangeNotifier {
  AuthController(this._service);
  final AuthService _service;

  AppUser? user;
  bool initializing = true;
  bool busy = false;
  String? error;

  bool get isLoggedIn => user != null;

  Future<void> init() async {
    try {
      user = await _service.restore();
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) => _run(() async => user = await _service.login(identifier, password));

  Future<bool> register({String? username, required String phone, required String password, required String role}) =>
      _run(() async => user = await _service.register(username: username, phone: phone, password: password, role: role));

  Future<bool> updateProfile({String? username, required String phone}) =>
      _run(() async => user = await _service.updateProfile(username: username, phone: phone));

  Future<bool> changePassword(String current, String next) => _run(() => _service.changePassword(current, next));

  /// Reload the user (e.g. is_verified changed after admin approval)
  Future<void> refreshMe() async {
    try {
      user = await _service.me();
      notifyListeners();
    } on ApiException {
      await logout();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
