import 'package:flutter/foundation.dart';

import '../../../../services/admin_service.dart';

class AdminActivityLogController extends ChangeNotifier {
  AdminActivityLogController(this._service);

  final AdminService _service;

  List<Map<String, dynamic>> _entries = const [];
  String? _action;
  DateTime? _since;
  Object? _error;
  bool _isLoading = false;
  bool _disposed = false;

  Object? get error => _error;
  bool get isLoading => _isLoading;
  String? get action => _action;
  DateTime? get since => _since;

  List<String> get availableActions =>
      (_entries
          .map((entry) => entry['action'])
          .whereType<String>()
          .toSet()
          .toList()
        ..sort());

  List<Map<String, dynamic>> get entries {
    final action = _action;
    final since = _since;
    if (action == null && since == null) return _entries;

    return List.unmodifiable(
      _entries.where((entry) {
        if (action != null && entry['action'] != action) return false;
        if (since == null) return true;

        final timestamp = entry['created_at'];
        final date = timestamp is String ? DateTime.tryParse(timestamp) : null;
        return date != null && !date.isBefore(since);
      }),
    );
  }

  /// An omitted action or date clears that filter.
  void setFilters({String? action, DateTime? since}) {
    if (_disposed || (action == _action && since == _since)) return;
    _action = action;
    _since = since;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final entries = await _service.logs();
      if (!_disposed) {
        _entries = List.unmodifiable(
          entries.map(Map<String, dynamic>.unmodifiable),
        );
      }
    } catch (error) {
      if (!_disposed) _error = error;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
