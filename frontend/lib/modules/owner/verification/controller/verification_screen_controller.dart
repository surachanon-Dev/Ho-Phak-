import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/verification.dart';
import '../services/verification_service.dart';

/// ผลการตรวจไฟล์เอกสารยืนยันตัวตนก่อนอัปโหลด
class DocumentCheck {
  const DocumentCheck._();

  /// คืนข้อความ error หรือ null ถ้าไฟล์ใช้ได้ (นามสกุลและขนาดตามกติกาเดิม)
  static String? validate({required String filename, required int sizeBytes}) {
    final dot = filename.lastIndexOf('.');
    final ext = dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();
    if (!VerificationService.documentExtensions.contains(ext)) {
      return 'Choose a PDF, JPG or PNG file';
    }
    if (sizeBytes > VerificationService.maxDocumentBytes) {
      return 'File is larger than 10 MB';
    }
    return null;
  }
}

/// หน้าการยืนยันตัวตนของเจ้าของ: โหลดสถานะ เลือกเอกสาร และส่ง
class VerificationScreenController extends ChangeNotifier {
  VerificationScreenController(this._verification);

  final VerificationService _verification;

  Verification? _current;
  UploadFile? _picked;
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  String? _pickError;

  Verification? get current => _current;
  UploadFile? get picked => _picked;
  bool get loading => _loading;
  bool get saving => _saving;
  Object? get error => _error;

  /// ข้อความ error ของการเลือกไฟล์ (ประเภท/ขนาดไม่ถูกต้อง)
  String? get pickError => _pickError;

  /// ส่งเอกสารใหม่ได้เมื่อยังไม่เคยส่ง หรือถูกปฏิเสธแล้ว
  bool get canSubmit =>
      _current == null || _current!.status == VerificationStatus.rejected;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _current = await _verification.current();
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// เลือกไฟล์ที่ผ่านการตรวจแล้ว ถ้าไม่ผ่านจะเก็บ pickError และไม่เลือกไฟล์
  bool pick(UploadFile file) {
    final problem = DocumentCheck.validate(
      filename: file.filename,
      sizeBytes: file.bytes.length,
    );
    if (problem != null) {
      _pickError = problem;
      _picked = null;
    } else {
      _pickError = null;
      _picked = file;
    }
    notifyListeners();
    return problem == null;
  }

  /// ส่งเอกสาร คืน true เมื่อสำเร็จ (แล้วโหลดสถานะใหม่)
  Future<bool> submit() async {
    final file = _picked;
    if (_saving || file == null || !canSubmit) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _verification.submit(file);
      _picked = null;
      _saving = false;
      notifyListeners();
      await load();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
