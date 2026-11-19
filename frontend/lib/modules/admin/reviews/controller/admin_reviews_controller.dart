import 'package:flutter/foundation.dart';

import '../../../../services/admin_service.dart';
import '../../../../core/network/api_client.dart';

enum AdminReviewStatus {
  open('open'),
  kept('published'),
  hidden('hidden');

  const AdminReviewStatus(this.apiStatus);

  final String apiStatus;
}

class AdminReviewsController extends ChangeNotifier {
  AdminReviewsController(this._service);

  final AdminService _service;

  AdminReviewStatus _status = AdminReviewStatus.open;
  List<Map<String, dynamic>> _reviews = const [];
  Object? _loadError;
  Object? _actionError;
  int _request = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _disposed = false;

  AdminReviewStatus get status => _status;
  List<Map<String, dynamic>> get reviews => _reviews;
  Object? get loadError => _loadError;
  Object? get actionError => _actionError;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;

  Future<void> selectStatus(AdminReviewStatus status) async {
    if (_disposed || _status == status) return;
    _status = status;
    _reviews = const [];
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;

    final request = ++_request;
    final status = _status;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final reviews = await _service.reviews(status.apiStatus);
      if (_isCurrent(request)) {
        _reviews = List.unmodifiable(
          reviews.map(Map<String, dynamic>.unmodifiable),
        );
      }
    } catch (error) {
      if (_isCurrent(request)) _loadError = error;
    } finally {
      if (_isCurrent(request)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Keeps an open review or restores a hidden review.
  Future<bool> publishReview(int id) =>
      _submit(() => _service.publishReview(id));

  Future<bool> hideReview(int id, String reason) => _submit(() async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ApiException(400, 'Please enter a reason for hiding the review');
    }
    await _service.hideReview(id, trimmed);
  });

  bool _isCurrent(int request) => !_disposed && request == _request;

  // A confirmed write returns true even when reloading the reviews fails.
  Future<bool> _submit(Future<void> Function() write) async {
    if (_disposed || _isSubmitting) return false;

    _isSubmitting = true;
    _actionError = null;
    notifyListeners();
    try {
      await write();
      if (!_disposed) {
        _reviews = const [];
        await refresh();
      }
      return true;
    } catch (error) {
      if (!_disposed) _actionError = error;
      return false;
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
