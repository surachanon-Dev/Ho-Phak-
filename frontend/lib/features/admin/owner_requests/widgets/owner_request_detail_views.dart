import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/admin/owner_requests/owner_request_item.dart';
import 'package:hopak_frontend/features/admin/owner_requests/widgets/owner_request_widgets.dart';

/// A-2a · รายละเอียดคำขอที่รอตรวจ (มีปุ่ม Reject / Approve)
class OwnerRequestPendingDetail extends StatelessWidget {
  const OwnerRequestPendingDetail({
    super.key,
    required this.item,
    required this.onBack,
    required this.onViewDocument,
    required this.onApprove,
    required this.onReject,
  });

  final OwnerRequestItem item;
  final VoidCallback onBack;
  final VoidCallback onViewDocument;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbHeader(
            parent: 'Owner requests',
            current: item.name,
            title: 'Owner request',
            onBack: onBack,
          ),
          const SizedBox(height: 18),

          // การ์ดข้อมูลผู้ขอ
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApplicantHeader(
                  initials: item.initials,
                  name: item.name,
                  subtitle: 'Owner account',
                ),
                const SizedBox(height: 20),
                DetailRow(label: 'Phone', value: item.phone),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(label: 'Role', value: item.role),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(label: 'Submitted', value: item.submitted),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(
                  label: 'Document',
                  customValue: DocumentLink(
                    name: item.documentName,
                    onTap: onViewDocument,
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(
                  label: 'Status',
                  customValue: const RequestStatusPill(status: 'Pending'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // แถบปุ่ม Reject / Approve ด้านล่าง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF0062D6),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Approving lets this owner add dorms. Rejecting needs a reason the owner will see and can resubmit (D-139, D-150).',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC92A2A),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062D6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A-2d · รายละเอียดคำขอที่ถูกปฏิเสธ (เห็นเหตุผล ไม่มีปุ่ม Approve/Reject)
class OwnerRequestRejectedDetail extends StatelessWidget {
  const OwnerRequestRejectedDetail({
    super.key,
    required this.item,
    required this.onBack,
    required this.onViewDocument,
  });

  final OwnerRequestItem item;
  final VoidCallback onBack;
  final VoidCallback onViewDocument;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbHeader(
            parent: 'Owner requests',
            current: item.name,
            title: 'Owner request',
            onBack: onBack,
          ),
          const SizedBox(height: 18),

          // กล่องแจ้งเตือนสีแดงด้านบน แสดงเวลาและเหตุผลที่แอดมินปฏิเสธ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF8CACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.block, size: 17, color: Color(0xFFC92A2A)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rejected by Admin · ${item.rejectedTimestamp ?? "7 Nov 2026 16:40"}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC92A2A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reason: ${item.rejectReason ?? "The name does not match your phone number. The owner can correct their details and resubmit."}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC92A2A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // การ์ดรายละเอียดผู้ขอ
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApplicantHeader(
                  initials: item.initials,
                  name: item.name,
                  subtitle: 'Owner account',
                ),
                const SizedBox(height: 20),
                DetailRow(label: 'Phone', value: item.phone),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(label: 'Role', value: item.role),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(label: 'Submitted', value: item.submitted),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(
                  label: 'Document',
                  customValue: DocumentLink(
                    name: item.documentName,
                    onTap: onViewDocument,
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                DetailRow(
                  label: 'Status',
                  customValue: const RequestStatusPill(status: 'Rejected'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // แถบข้อความแจ้งด้านล่าง (ไม่มีปุ่ม Approve/Reject)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF0062D6)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This request was rejected. The owner can edit their details and send a new request (D-150).',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
