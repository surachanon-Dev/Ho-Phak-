import 'package:hopak_frontend/features/admin/user_detail/user_detail_controller.dart';
import 'package:hopak_frontend/features/admin/owner_requests/owner_requests_controller.dart';

/// คำขอเป็นเจ้าของหอ 1 รายการ ในรูปที่หน้า Owner requests ใช้แสดงผล
class OwnerRequestItem {
  /// แปลงแถวจาก GET /api/admin/verifications เป็นรายการที่หน้าจอใช้
  factory OwnerRequestItem.fromRow(Map<String, dynamic> row) {
    final status = switch (row['status']) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending',
    };
    final name = AdminOwnerRequestsController.displayName(row);
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    final url = (row['document_url'] as String?) ?? '';
    return OwnerRequestItem(
      id: '${row['id']}',
      initials: initials.isEmpty ? '?' : initials,
      name: name,
      phone: (row['owner_phone'] as String?) ?? '-',
      role: 'Dorm Owner',
      submitted: AdminUserDetailController.formatDate(row['submitted_at']),
      reviewedDate: row['reviewed_at'] == null
          ? null
          : AdminUserDetailController.formatDate(row['reviewed_at']),
      documentName: url.isEmpty ? '-' : url.split('/').last,
      status: status,
      rejectReason: row['rejection_reason'] as String?,
    );
  }

  const OwnerRequestItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.phone,
    required this.role,
    required this.submitted,
    required this.documentName,
    required this.status,
    this.reviewedDate,
    this.rejectedTimestamp,
    this.rejectReason,
  });

  final String id;
  final String initials;
  final String name;
  final String phone;
  final String role;
  final String submitted;
  final String? reviewedDate;
  final String? rejectedTimestamp;
  final String? rejectReason;
  final String documentName;
  final String status;

  OwnerRequestItem copyWith({
    String? status,
    String? reviewedDate,
    String? rejectedTimestamp,
    String? rejectReason,
  }) {
    return OwnerRequestItem(
      id: id,
      initials: initials,
      name: name,
      phone: phone,
      role: role,
      submitted: submitted,
      documentName: documentName,
      status: status ?? this.status,
      reviewedDate: reviewedDate ?? this.reviewedDate,
      rejectedTimestamp: rejectedTimestamp ?? this.rejectedTimestamp,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
