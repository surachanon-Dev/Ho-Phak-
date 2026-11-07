import '../models/verification.dart';
import 'api_client.dart';

class VerificationService {
  VerificationService(this._api);

  final ApiClient _api;

  /// GET /api/owner/verification → { verification: {...} | null }
  Future<Verification?> current() async {
    final data =
        await _api.get('/api/owner/verification') as Map<String, dynamic>;
    final v = data['verification'];
    return v == null ? null : Verification.fromJson(v as Map<String, dynamic>);
  }

  /// POST /api/owner/verification { document_url }
  /// ยังไม่มีการอัปโหลดไฟล์จริง รับเป็น URL ไปก่อน
  Future<void> submit(String documentUrl) =>
      _api.post('/api/owner/verification', {'document_url': documentUrl});
}
