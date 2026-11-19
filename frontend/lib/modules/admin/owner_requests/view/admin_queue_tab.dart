import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/session.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../widgets/document_viewer.dart';
import '../../../../widgets/ui/ui.dart';
import '../../../../services/admin_service.dart';
import '../../widgets/admin_page.dart';
import '../controller/admin_owner_requests_controller.dart';

import '../model/owner_request_item.dart';
import 'widgets/owner_request_widgets.dart';
import 'widgets/owner_request_detail_views.dart';
import 'widgets/reject_request_dialog.dart';

/// หน้า Owner requests: คำขอเป็นเจ้าของหอ (รายการรอตรวจ อนุมัติ/ปฏิเสธ และดูประวัติ)
class AdminQueueTab extends StatefulWidget {
  const AdminQueueTab({super.key, required this.services, this.onChanged});

  final AppServices services;

  /// เรียกหลังอนุมัติ/ปฏิเสธสำเร็จ เพื่อให้ badge เมนูและแดชบอร์ดโหลดตัวเลขใหม่
  final VoidCallback? onChanged;

  @override
  State<AdminQueueTab> createState() => _AdminQueueTabState();
}

enum _OwnerRequestSubView {
  list, // A-2 (Pending) / Approved / A-2c (Rejected tab)
  detailPending, // A-2a (Owner request – detail)
  detailRejected, // A-2d (Owner request – rejected)
}

class _AdminQueueTabState extends State<AdminQueueTab> {
  // 0 = Pending, 1 = Approved, 2 = Rejected
  int _selectedTab = 0;
  String _searchQuery = '';
  _OwnerRequestSubView _subView = _OwnerRequestSubView.list;
  OwnerRequestItem? _selectedItem;
  late final AdminOwnerRequestsController _c;

  @override
  void initState() {
    super.initState();
    _c = AdminOwnerRequestsController(AdminService(widget.services.api));
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.load().then((ok) {
      if (!ok && mounted && _c.error != null) {
        showApiError(context, widget.services, _c.error!);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<OwnerRequestItem> get _pendingItems =>
      _c.pending.map(OwnerRequestItem.fromRow).toList();

  List<OwnerRequestItem> get _approvedItems =>
      _c.approved.map(OwnerRequestItem.fromRow).toList();

  List<OwnerRequestItem> get _rejectedItems =>
      _c.rejected.map(OwnerRequestItem.fromRow).toList();

  void _openReview(OwnerRequestItem item) {
    setState(() {
      _selectedItem = item;
      if (item.status == 'Rejected') {
        _subView = _OwnerRequestSubView.detailRejected;
      } else {
        _subView = _OwnerRequestSubView.detailPending;
      }
    });
  }

  void _backToList() {
    setState(() {
      _subView = _OwnerRequestSubView.list;
      _selectedItem = null;
    });
  }

  /// เปิดดูเอกสารยืนยันตัวตน (ดึงไฟล์พร้อม token ของแอดมิน)
  Future<void> _viewDocument(OwnerRequestItem item) async {
    final Uint8List bytes;
    try {
      bytes = await AdminService(widget.services.api)
          .verificationDocument(int.parse(item.id));
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
      return;
    }
    if (!mounted) return;
    await showDocumentViewer(context, name: item.documentName, bytes: bytes);
  }

  Future<void> _approveRequest(OwnerRequestItem item) async {
    final ok = await _c.approve(int.parse(item.id));
    if (!mounted) return;
    if (ok) {
      widget.onChanged?.call();
      setState(() {
        _subView = _OwnerRequestSubView.list;
        _selectedItem = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved ${item.name} successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  // A-2b · Owner request – reject dialog (ป๊อปอัปกรอกเหตุผลตอน Reject)
  Future<void> _showRejectDialog(OwnerRequestItem item) async {
    final confirmedReason = await showRejectRequestDialog(
      context,
      applicantName: item.name,
    );

    if (confirmedReason == null || !mounted) return;
    final ok = await _c.reject(int.parse(item.id), confirmedReason);
    if (!mounted) return;
    if (ok) {
      widget.onChanged?.call();
      setState(() {
        _subView = _OwnerRequestSubView.list;
        _selectedItem = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rejected ${item.name}. They can correct and resubmit.',
          ),
        ),
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_subView) {
      case _OwnerRequestSubView.detailPending:
        return OwnerRequestPendingDetail(
          item: _selectedItem!,
          onBack: _backToList,
          onViewDocument: () => _viewDocument(_selectedItem!),
          onApprove: () => _approveRequest(_selectedItem!),
          onReject: () => _showRejectDialog(_selectedItem!),
        );
      case _OwnerRequestSubView.detailRejected:
        return OwnerRequestRejectedDetail(
          item: _selectedItem!,
          onBack: _backToList,
          onViewDocument: () => _viewDocument(_selectedItem!),
        );
      case _OwnerRequestSubView.list:
        return _buildListView();
    }
  }

  Widget _buildListView() {
    final sourceList = _selectedTab == 0
        ? _pendingItems
        : (_selectedTab == 1 ? _approvedItems : _rejectedItems);

    final filtered = sourceList.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.phone.toLowerCase().contains(q);
    }).toList();

    final wide = isWideLayout(context);
    final search = SearchField(
      hint: 'Search name or phone...',
      onChanged: (v) => setState(() => _searchQuery = v),
    );
    final tabs = RequestTabBar(
      children: [
        RequestTabButton(
          label: 'Pending',
          count: _pendingItems.length,
          selected: _selectedTab == 0,
          onTap: () => setState(() => _selectedTab = 0),
        ),
        RequestTabButton(
          label: 'Approved',
          count: _approvedItems.length,
          selected: _selectedTab == 1,
          onTap: () => setState(() => _selectedTab = 1),
        ),
        RequestTabButton(
          label: 'Rejected',
          count: _rejectedItems.length,
          selected: _selectedTab == 2,
          onTap: () => setState(() => _selectedTab = 2),
        ),
      ],
    );

    final noun = filtered.length == 1 ? 'request' : 'requests';

    return AdminPage(
      title: 'Owner requests',
      subtitle: 'Check identity documents before owners can list dorms',
      toolbar: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: tabs),
                const SizedBox(width: 16),
                SizedBox(width: 280, child: search),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tabs, const SizedBox(height: 10), search],
            ),
      child: filtered.isEmpty
          ? EmptyState(
              icon: _searchQuery.isEmpty
                  ? Icons.inbox_outlined
                  : Icons.search_off_rounded,
              tone: _searchQuery.isEmpty ? Tone.success : Tone.neutral,
              title: 'No requests',
              message: _searchQuery.isEmpty
                  ? 'Owner requests in this tab will appear here.'
                  : 'Try another name or phone number.',
            )
          : AdminListView(
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _selectedTab == 2
                          ? 'Showing all ${filtered.length} $noun · a resubmitted document moves the request back to Pending.'
                          : 'Showing all ${filtered.length} $noun',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return _RequestCard(
                  item: filtered[i],
                  wide: wide,
                  rejectedTab: _selectedTab == 2,
                  actionLabel: _selectedTab == 0 ? 'Review' : 'View',
                  onOpen: () => _openReview(filtered[i]),
                  onViewDocument: () => _viewDocument(filtered[i]),
                );
              },
            ),
    );
  }
}

/// คำขอ 1 รายการ: จอกว้างเรียงเป็นแถว จอแคบซ้อนเป็นการ์ด
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.item,
    required this.wide,
    required this.rejectedTab,
    required this.actionLabel,
    required this.onOpen,
    required this.onViewDocument,
  });

  final OwnerRequestItem item;
  final bool wide;
  final bool rejectedTab;
  final String actionLabel;
  final VoidCallback onOpen;
  final VoidCallback onViewDocument;

  @override
  Widget build(BuildContext context) {
    final identity = Row(
      children: [
        InitialsAvatar(name: item.name, size: 42, tone: Tone.violet),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.phone,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final dateText = rejectedTab
        ? (item.reviewedDate ?? item.submitted)
        : item.submitted;
    final date = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.event_outlined, size: 15, color: AppColors.textFaint),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            dateText,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textBody),
          ),
        ),
      ],
    );

    final detail = rejectedTab
        ? Text(
            item.rejectReason ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textBody),
          )
        : DocumentLink(name: item.documentName, onTap: onViewDocument);

    if (wide) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(flex: 3, child: identity),
            Expanded(flex: 2, child: date),
            Expanded(
              flex: 4,
              child: Align(alignment: Alignment.centerLeft, child: detail),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: RequestStatusPill(status: item.status),
              ),
            ),
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 8),
              RequestStatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: 12),
          date,
          const SizedBox(height: 10),
          detail,
        ],
      ),
    );
  }
}
