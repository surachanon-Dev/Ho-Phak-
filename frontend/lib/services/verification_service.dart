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

  /// POST /api/owner/verification (multipart) ไฟล์เดียวในช่อง "document"
  /// รองรับ pdf, jpg, png ไม่เกิน 10 MB
  Future<void> submit(UploadFile document) => _api.uploadFiles(
    '/api/owner/verification',
    fieldName: 'document',
    files: [document],
  );
}
