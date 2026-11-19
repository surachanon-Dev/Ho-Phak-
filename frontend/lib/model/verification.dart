/// สถานะการยืนยันตัวตนเจ้าของ: pending | approved | rejected
class VerificationStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static String label(String status) => switch (status) {
    VerificationStatus.pending => 'Pending review',
    VerificationStatus.approved => 'Verified',
    VerificationStatus.rejected => 'Rejected',
    _ => status,
  };
}

/// ผลจาก GET /api/owner/verification → { verification: {...} | null }
class Verification {
  Verification({required this.status, this.documentUrl, this.reason});

  final String status;
  final String? documentUrl;

  /// เหตุผลเมื่อถูกปฏิเสธ (ชื่อ field ยังไม่ยืนยันกับทีม backend)
  final String? reason;

  factory Verification.fromJson(Map<String, dynamic> json) => Verification(
    status: (json['status'] as String?) ?? VerificationStatus.pending,
    documentUrl: json['document_url'] as String?,
    reason: (json['rejection_reason'] ?? json['reason']) as String?,
  );
}
