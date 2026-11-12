import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/dormitory.dart';
import '../services/owner_service.dart';

/// Owner dashboard + dorm list state
class OwnerController extends ChangeNotifier {
  OwnerController(this.service);
  final OwnerService service;

  OwnerStats? stats;
  List<Dormitory> dorms = [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      stats = await service.stats();
      dorms = await service.myDorms();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
