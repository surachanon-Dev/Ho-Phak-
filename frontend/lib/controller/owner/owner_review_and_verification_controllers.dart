import 'package:flutter/foundation.dart';

import '../../models/verification.dart';
import '../../services/api_client.dart';
import 'dormitory_controller.dart';
import 'owner_extras.dart';
import 'verification_controller.dart';

/// หน้ารีวิวของฉัน (อ่านอย่างเดียว + report): โหลดรีวิวทุกหอ กรองตามหอ และ report รีวิว
class MyReviewsController extends ChangeNotifier {
  MyReviewsController(this._dorms);

  /// เหตุผลการ report ยาวสุด (ตรงกับกติกาในหน้าจอ)
  static const maxReportReasonLength = 300;

  final DormitoryController _dorms;

  List<OwnerReviewEntry> _all = const [];
  List<String> _dormNames = const [];
  Map<int, ReviewReport> _reports = const {};
  String? _filter;
  bool _loading = true;
  Object? _error;

  bool get loading => _loading;
  Object? get error => _error;

  /// แสดงสปินเนอร์เต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _all.isEmpty;

  /// ชื่อหอทั้งหมดที่มีรีวิว
  List<String> get dormNames => _dormNames;

  /// ชื่อหอที่กรองอยู่ (null = ทุกหอ)
  String? get filter => _filter;

  /// รีวิวที่แสดงหลังกรอง
  List<OwnerReviewEntry> get visible =>
      OwnerReviewsBundle(_all, _dormNames).visible(_filter);

  /// ค่าเฉลี่ยของรีวิวที่แสดงอยู่ (null ถ้าไม่มี)
  double? get average => OwnerReviewsBundle.average(visible);

  /// รีวิวที่ report ไปแล้ว (key = review id)
  bool isReported(int reviewId) => _reports.containsKey(reviewId);

  void setFilter(String? dormName) {
    _filter = (dormName != null && _dormNames.contains(dormName)) ? dormName : null;
    notifyListeners();
  }

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      final bundle = await _dorms.allReviews();
      final reports = await _dorms.reviewReports();
      _all = bundle.entries;
      _dormNames = bundle.dormNames;
      _reports = reports;
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

  /// report รีวิว: เหตุผลต้องไม่ว่างและไม่เกิน 300 ตัวอักษร คืน true เมื่อสำเร็จ
  Future<bool> report(int reviewId, String reason) async {
    final text = reason.trim();
    if (text.isEmpty || text.length > maxReportReasonLength) {
      _error = ArgumentError.value(reason, 'reason', 'เหตุผลต้องมี 1–$maxReportReasonLength ตัวอักษร');
      notifyListeners();
      return false;
    }
    try {
      await _dorms.reportReview(reviewId, text);
      _reports = await _dorms.reviewReports();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }
}

/// ผลการตรวจไฟล์เอกสารยืนยันตัวตนก่อนอัปโหลด
class DocumentCheck {
  const DocumentCheck._();

  /// คืนข้อความ error หรือ null ถ้าไฟล์ใช้ได้ (นามสกุลและขนาดตามกติกาเดิม)
  static String? validate({required String filename, required int sizeBytes}) {
    final dot = filename.lastIndexOf('.');
    final ext = dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();
    if (!VerificationController.documentExtensions.contains(ext)) {
      return 'Choose a PDF, JPG or PNG file';
    }
    if (sizeBytes > VerificationController.maxDocumentBytes) {
      return 'File is larger than 10 MB';
    }
    return null;
  }
}

/// หน้าการยืนยันตัวตนของเจ้าของ: โหลดสถานะ เลือกเอกสาร และส่ง
class VerificationScreenController extends ChangeNotifier {
  VerificationScreenController(this._verification);

  final VerificationController _verification;

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
