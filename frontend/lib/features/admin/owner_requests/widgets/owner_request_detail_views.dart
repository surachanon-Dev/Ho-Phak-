import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/ui/ui.dart';
import '../../widgets/admin_page.dart';
import '../owner_request_item.dart';
import 'owner_request_widgets.dart';
import 'reject_request_dialog.dart';

/// การ์ดข้อมูลผู้ขอ (ใช้ทั้งรายการรอตรวจและที่ถูกปฏิเสธ)
class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.item, required this.onViewDocument});

  final OwnerRequestItem item;
  final VoidCallback onViewDocument;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApplicantHeader(
            initials: item.initials,
            name: item.name,
            subtitle: 'Owner account',
            trailing: RequestStatusPill(status: item.status),
          ),
          const SizedBox(height: 12),
          const Divider(),
          DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: item.phone,
          ),
          const Divider(),
          DetailRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: item.role,
          ),
          const Divider(),
          DetailRow(
            icon: Icons.event_outlined,
            label: 'Submitted',
            value: item.submitted,
          ),
          const Divider(),
          DetailRow(
            icon: Icons.attach_file_rounded,
            label: 'Document',
            customValue: DocumentLink(
              name: item.documentName,
              onTap: onViewDocument,
            ),
          ),
        ],
      ),
    );
  }
}

/// โครงหน้ารายละเอียด: จอกว้างแบ่งซ้าย (ข้อมูล) / ขวา (การตัดสินใจ)
class _DetailFrame extends StatelessWidget {
  const _DetailFrame({
    required this.item,
    required this.onBack,
    required this.main,
    required this.side,
  });

  final OwnerRequestItem item;
  final VoidCallback onBack;
  final Widget main;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    final pad = adminPagePadding(context);
    final wide = isWideLayout(context);
    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        ContentWidth(
          maxWidth: 1100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BreadcrumbHeader(
                parent: 'Owner requests',
                current: item.name,
                title: 'Owner request',
                onBack: onBack,
              ),
              const SizedBox(height: 20),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: main),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: side),
                  ],
                )
              else ...[
                main,
                const SizedBox(height: 16),
                side,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// รายละเอียดคำขอที่รอตรวจ (มีปุ่ม Reject / Approve)
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
    return _DetailFrame(
      item: item,
      onBack: onBack,
      main: _ApplicantCard(item: item, onViewDocument: onViewDocument),
      side: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Decision', icon: Icons.gavel_rounded),
            const SizedBox(height: 12),
            const NoticeBanner(
              tone: Tone.info,
              message: 'Approving lets this owner add dorms. Rejecting needs a reason the owner will see and can resubmit.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: item.documentName == '-' ? null : onViewDocument,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Open document'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: Color(0xFFF3B4B4)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: primaryElevatedStyle(),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// รายละเอียดคำขอที่ถูกปฏิเสธ (เห็นเหตุผล ไม่มีปุ่ม Approve/Reject)
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
    final when = item.rejectedTimestamp ?? item.reviewedDate;
    return _DetailFrame(
      item: item,
      onBack: onBack,
      main: _ApplicantCard(item: item, onViewDocument: onViewDocument),
      side: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeBanner(
            tone: Tone.danger,
            icon: Icons.block,
            title: when == null
                ? 'Rejected by Admin'
                : 'Rejected by Admin · $when',
            message: 'Reason: ${item.rejectReason ?? '-'}',
          ),
          const SizedBox(height: 12),
          const NoticeBanner(
            tone: Tone.info,
            message: 'This request was rejected. The owner can edit their details and send a new request.',
          ),
        ],
      ),
    );
  }
}
