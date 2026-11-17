import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'admin_owner_requests_controller.dart';
import '../services/admin_service.dart';
import '../../../core/app_services.dart';
import '../../../core/utils/error_handling.dart';
import '../../../shared/widgets/document_viewer.dart';
import '../../../core/utils/responsive.dart';

import 'owner_request_item.dart';
import 'widgets/owner_request_widgets.dart';
import 'widgets/owner_request_detail_views.dart';
import 'widgets/reject_request_dialog.dart';

/// หน้า 03 · OWNER REQUESTS — คำขอเป็นเจ้าของหอ (หน้า A-2, A-2a, A-2c, A-2d: รายการรอตรวจ อนุมัติ/ปฏิเสธ และดูประวัติ)
/// วางทับที่: ช่องที่ 5 ในโฟลเดอร์ admin (lib/features/admin/owner_requests/admin_queue_tab.dart)
/// ใช้เฉพาะ import มาตรฐานและ AppServices ของโปรเจกต์ 100% เพื่อไม่ให้ขึ้นสีแดง
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
          backgroundColor: const Color(0xFF15803D),
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
        // ตารางกว้าง 1000 พิกเซล เลื่อนแนวนอนได้เมื่อหน้าจอแคบกว่า (ปุ่ม Review ไม่ถูกตัด)
        return _buildListView();
    }
  }

  // ===========================================================================
  // A-2 (Pending) & A-2c (Rejected tab)
  // ===========================================================================
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถบแท็บ Pending / Approved / Rejected + ช่องค้นหา
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RequestTabButton(
                label: 'Pending',
                count: _pendingItems.length,
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 20),
              RequestTabButton(
                label: 'Approved',
                count: _approvedItems.length,
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              const SizedBox(width: 20),
              RequestTabButton(
                label: 'Rejected',
                count: _rejectedItems.length,
                selected: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
              const SizedBox(width: 12),
              // ช่อง Search name or phone...
              SizedBox(
                width: 240,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search name or phone...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0062D6)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          // ตารางรายการคำขอ (จอกว้าง) / การ์ดรายการ (จอแคบ)
          if (isWideLayout(context))
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // หัวตารางเปลี่ยนตามแท็บ (Pending vs Rejected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'APPLICANT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _selectedTab == 2 ? 'REVIEWED' : 'SUBMITTED',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            _selectedTab == 2 ? 'REASON' : 'DOCUMENT',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 84),
                      ],
                    ),
                  ),

                  for (int i = 0; i < filtered.length; i++) ...[
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // APPLICANT (ชื่อ + เบอร์โทร)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filtered[i].name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  filtered[i].phone,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // SUBMITTED หรือ REVIEWED
                          Expanded(
                            flex: 2,
                            child: Text(
                              _selectedTab == 2
                                  ? (filtered[i].reviewedDate ??
                                        filtered[i].submitted)
                                  : filtered[i].submitted,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),

                          // DOCUMENT หรือ REASON
                          Expanded(
                            flex: 4,
                            child: _selectedTab == 2
                                ? Text(
                                    filtered[i].rejectReason ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                    ),
                                  )
                                : DocumentLink(
                                    name: filtered[i].documentName,
                                    onTap: () => _viewDocument(filtered[i]),
                                  ),
                          ),

                          // STATUS Pill
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RequestStatusPill(
                                status: filtered[i].status,
                              ),
                            ),
                          ),

                          // ปุ่ม Review หรือ View
                          SizedBox(
                            width: 84,
                            child: OutlinedButton(
                              onPressed: () => _openReview(filtered[i]),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _selectedTab == 0 ? 'Review' : 'View',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // คำอธิบายใต้ตารางในแท็บ Rejected (A-2c)
          if (_selectedTab == 2) ...[
            const SizedBox(height: 12),
            const Text(
              'A resubmitted document overwrites this request and moves it back to Pending (D-94).',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],

          if (!isWideLayout(context)) _requestCards(filtered),
          const SizedBox(height: 14),

          // Pagination ด้านล่างตาราง
          Row(
            children: [
              Text(
                'Showing all ${filtered.length} ${filtered.length == 1 ? 'request' : 'requests'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // A-2a · Owner request – detail (รายละเอียดผู้ขอ + ปุ่ม Reject / Approve)
  // ===========================================================================
  /// รายการคำขอแบบการ์ดสำหรับจอแคบ (กดการ์ดเพื่อเปิดหน้ารายละเอียด)
  Widget _requestCards(List<OwnerRequestItem> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No requests',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openReview(item),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFDBEAFE),
                          child: Text(
                            item.initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0062D6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                item.phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        RequestStatusPill(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedTab == 2
                          ? 'Reviewed: ${item.reviewedDate ?? '-'}'
                          : 'Submitted: ${item.submitted}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_selectedTab == 2)
                      Text(
                        item.rejectReason ?? '-',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      )
                    else
                      DocumentLink(
                        name: item.documentName,
                        onTap: () => _viewDocument(item),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
