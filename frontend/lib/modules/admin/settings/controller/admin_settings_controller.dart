import 'package:flutter/foundation.dart';

import '../../../../model/user.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/auth_service.dart';

typedef AdminPasswordUpdater = Future<void> Function({
  required String currentPassword,
  required String newPassword,
});

enum AdminSettingsActivity { idle, loading, changingPassword, signingOut }

class AdminSettingsController extends ChangeNotifier {
  AdminSettingsController({
    required this._api,
    required this._auth,
    this._updatePassword,
  });

  final ApiClient _api;
  final AuthService _auth;
  final AdminPasswordUpdater? _updatePassword;

  CurrentUser? _account;
  String? _supportPhone;
  Object? _error;
  var _activity = AdminSettingsActivity.idle;
  bool _disposed = false;

  CurrentUser? get account => _account;
  String? get supportPhone => _supportPhone;
  Object? get error => _error;
  AdminSettingsActivity get activity => _activity;

  Future<bool> loadAccount() => _run(AdminSettingsActivity.loading, () async {
    // The account response includes the support number used by this page.
    final data = await _api.get('/api/me') as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final account = CurrentUser.fromJson(user);
    if (!_disposed) {
      _account = account;
      _supportPhone = user['phone']?.toString();
    }
  });

  Future<bool> signOut() => _run(AdminSettingsActivity.signingOut, () async {
    await _auth.logout();
    if (!_disposed) {
      _account = null;
      _supportPhone = null;
    }
  });

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => _run(AdminSettingsActivity.changingPassword, () async {
    if (currentPassword.isEmpty) {
      throw ApiException(400, 'Enter your current password');
    }
    if (newPassword.length < 8) {
      throw ApiException(400, 'Use at least 8 characters');
    }
    if (newPassword != confirmPassword) {
      throw ApiException(400, 'Passwords do not match');
    }

    final updatePassword = _updatePassword;
    if (updatePassword == null) {
      throw ApiException(501, 'Password changes are unavailable');
    }
    await updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  });

  Future<bool> _run(
    AdminSettingsActivity activity,
    Future<void> Function() operation,
  ) async {
    if (_disposed || _activity != AdminSettingsActivity.idle) return false;

    _activity = activity;
    _error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } catch (error) {
      if (!_disposed) _error = error;
      return false;
    } finally {
      _activity = AdminSettingsActivity.idle;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
