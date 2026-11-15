import 'package:flutter/material.dart';

import '../../services/app_services.dart';

/// หน้า 03 · OWNER REQUESTS — คำขอเป็นเจ้าของหอ (ครบทั้ง 6 หน้าจอ: A-2, A-2a, A-2b, A-2c, A-2d, A-2e)
/// วางทับที่: ช่องที่ 5 ในโฟลเดอร์ admin (lib/screens/admin/admin_queue_tab.dart)
/// ใช้เฉพาะ import มาตรฐานและ AppServices ของโปรเจกต์ 100% เพื่อไม่ให้ขึ้นสีแดง
class AdminQueueTab extends StatefulWidget {
  const AdminQueueTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminQueueTab> createState() => _AdminQueueTabState();
}

enum _OwnerRequestSubView {
  list, // A-2 (Pending) / Approved / A-2c (Rejected tab)
  detailPending, // A-2a (Owner request – detail)
  detailRejected, // A-2d (Owner request – rejected)
  detailPhoneChange, // A-2e (Owner request – phone change)
}

class _AdminQueueTabState extends State<AdminQueueTab> {
  // 0 = Pending, 1 = Approved, 2 = Rejected
  int _selectedTab = 0;
  String _searchQuery = '';
  _OwnerRequestSubView _subView = _OwnerRequestSubView.list;
  _OwnerRequestItem? _selectedItem;

  final List<_OwnerRequestItem> _pendingItems = [
    _OwnerRequestItem(
      id: 'req-1',
      initials: 'SJ',
      name: 'Somchai Jaidee',
      phone: '081-234-5678',
      newPhone: '081-999-0000',
      role: 'Dorm Owner',
      memberSince: '2 Sep 2026',
      accountApprovedDate: '3 Sep 2026',
      submitted: 'Today 08:31',
      documentName: 'business-licence.jpg',
      status: 'Pending',
      isPhoneChange: false,
    ),
    _OwnerRequestItem(
      id: 'req-2',
      initials: 'PW',
      name: 'Pimchanok Wongsa',
      phone: '089-552-1043',
      role: 'Dorm Owner',
      memberSince: '10 Oct 2026',
      submitted: 'Yesterday 19:12',
      documentName: 'title-deed.pdf',
      status: 'Pending',
      isPhoneChange: false,
    ),
    _OwnerRequestItem(
      id: 'req-3',
      initials: 'AK',
      name: 'Arthit Kaewmanee',
      phone: '062-110-7789',
      role: 'Dorm Owner',
      memberSince: '1 Nov 2026',
      submitted: '6 Nov 2026',
      documentName: 'lease-contract.pdf',
      status: 'Pending',
      isPhoneChange: false,
    ),
    _OwnerRequestItem(
      id: 'req-phone-1',
      initials: 'SJ',
      name: 'Somchai Jaidee',
      phone: '081-234-5678',
      newPhone: '081-999-0000',
      role: 'Dorm Owner',
      memberSince: '2 Sep 2026',
      accountApprovedDate: '3 Sep 2026',
      submitted: 'Today 10:12',
      documentName: 'phone-change-request',
      status: 'Pending',
      isPhoneChange: true,
    ),
  ];

  final List<_OwnerRequestItem> _approvedItems = [
    _OwnerRequestItem(
      id: 'app-1',
      initials: 'KS',
      name: 'Kanya Srisuk',
      phone: '081-555-8899',
      role: 'Dorm Owner',
      memberSince: '15 Aug 2026',
      submitted: 'Yesterday 17:03',
      reviewedDate: 'Yesterday 17:03',
      documentName: 'business-licence.pdf',
      status: 'Approved',
    ),
  ];

  final List<_OwnerRequestItem> _rejectedItems = [
    _OwnerRequestItem(
      id: 'rej-1',
      initials: 'NT',
      name: 'Narin Thongdee',
      phone: '086-301-2290',
      role: 'Dorm Owner',
      memberSince: '20 Oct 2026',
      submitted: '5 Nov 2026 09:12',
      reviewedDate: '5 Nov 2026',
      rejectedTimestamp: '5 Nov 2026 14:20',
      rejectReason:
          'The document is blurry — please upload a clear photo of your business licence.',
      documentName: 'business-licence.jpg',
      status: 'Rejected',
    ),
    _OwnerRequestItem(
      id: 'rej-2',
      initials: 'MC',
      name: 'Malee Chaiyo',
      phone: '091-778-3321',
      role: 'Dorm Owner',
      memberSince: '18 Oct 2026',
      submitted: '1 Nov 2026 10:05',
      reviewedDate: '1 Nov 2026',
      rejectedTimestamp: '1 Nov 2026 15:10',
      rejectReason:
          'The name on the title deed does not match the account name.',
      documentName: 'title-deed.pdf',
      status: 'Rejected',
    ),
    _OwnerRequestItem(
      id: 'rej-3',
      initials: 'SJ',
      name: 'Somchai Jaidee',
      phone: '081-234-5678',
      role: 'Dorm Owner',
      memberSince: '2 Sep 2026',
      submitted: '7 Nov 2026 09:12',
      reviewedDate: '7 Nov 2026',
      rejectedTimestamp: '7 Nov 2026 16:40',
      rejectReason:
          'The name does not match your phone number. The owner can correct their details and resubmit.',
      documentName: 'business-licence.jpg',
      status: 'Rejected',
    ),
  ];

  void _openReview(_OwnerRequestItem item) {
    setState(() {
      _selectedItem = item;
      if (item.status == 'Rejected') {
        _subView = _OwnerRequestSubView.detailRejected;
      } else if (item.isPhoneChange) {
        _subView = _OwnerRequestSubView.detailPhoneChange;
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

  void _approveRequest(_OwnerRequestItem item) {
    setState(() {
      _pendingItems.removeWhere((e) => e.id == item.id);
      _approvedItems.insert(
        0,
        item.copyWith(
          status: 'Approved',
          reviewedDate: 'Today',
        ),
      );
      _subView = _OwnerRequestSubView.list;
      _selectedItem = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approved ${item.name} successfully.'),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  // A-2b · Owner request – reject dialog (ป๊อปอัปกรอกเหตุผลตอน Reject)
  Future<void> _showRejectDialog(_OwnerRequestItem item) async {
    final controller = TextEditingController(
      text:
          'The document is blurry — please upload a clear photo of your business licence.',
    );

    final confirmedReason = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentLength = controller.text.length;
            final canSubmit =
                controller.text.trim().isNotEmpty && currentLength <= 300;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reject owner request?',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.name} will see this reason in the app and can correct their details and resubmit.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reason (required)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      maxLength: 300,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0062D6),
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0062D6),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentLength / 300',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: canSubmit
                              ? () => Navigator.of(ctx)
                                  .pop(controller.text.trim())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC92A2A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
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
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmedReason != null && mounted) {
      setState(() {
        _pendingItems.removeWhere((e) => e.id == item.id);
        final rejectedItem = item.copyWith(
          status: 'Rejected',
          reviewedDate: '7 Nov 2026',
          rejectedTimestamp: '7 Nov 2026 16:40',
          rejectReason: confirmedReason,
        );
        _rejectedItems.insert(0, rejectedItem);
        _selectedItem = rejectedItem;
        _subView = _OwnerRequestSubView.detailRejected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_subView) {
      case _OwnerRequestSubView.detailPending:
        return _buildDetailPending(_selectedItem!);
      case _OwnerRequestSubView.detailRejected:
        return _buildDetailRejected(_selectedItem!);
      case _OwnerRequestSubView.detailPhoneChange:
        return _buildDetailPhoneChange(_selectedItem!);
      case _OwnerRequestSubView.list:
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถบแท็บ Pending / Approved / Rejected + ช่องค้นหา
          Row(
            children: [
              _TabButton(
                label: 'Pending',
                count: _pendingItems.length,
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 20),
              _TabButton(
                label: 'Approved',
                count: 12,
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              const SizedBox(width: 20),
              _TabButton(
                label: 'Rejected',
                count: _rejectedItems.length,
                selected: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
              const Spacer(),

              // ปุ่มลัดเปิดดูหน้า A-2d และ A-2e ได้ทันที
              OutlinedButton.icon(
                onPressed: () => _openReview(_pendingItems.last),
                icon: const Icon(Icons.phone_iphone, size: 15),
                label: const Text(
                  'ดูหน้า A-2e (ขอเปลี่ยนเบอร์)',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0062D6),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  backgroundColor: const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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

          // ตารางรายการคำขอ
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
                                filtered[i].isPhoneChange
                                    ? '${filtered[i].name} (Phone change)'
                                    : filtered[i].name,
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
                              : Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file_outlined,
                                      size: 15,
                                      color: Color(0xFF0062D6),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        filtered[i].documentName,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0062D6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        // STATUS Pill
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _StatusPill(status: filtered[i].status),
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
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Pagination ด้านล่างตาราง
          Row(
            children: [
              Text(
                'Showing 1–${filtered.length} of ${filtered.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              _PageArrowButton(icon: Icons.chevron_left, onTap: () {}),
              const SizedBox(width: 6),
              _PageArrowButton(icon: Icons.chevron_right, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // A-2a · Owner request – detail (รายละเอียดผู้ขอ + ปุ่ม Reject / Approve)
  // ===========================================================================
  Widget _buildDetailPending(_OwnerRequestItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BreadcrumbHeader(
            parent: 'Owner requests',
            current: item.name,
            title: 'Owner request',
            onBack: _backToList,
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
                _ApplicantHeader(
                  initials: item.initials,
                  name: item.name,
                  subtitle: 'Owner account',
                ),
                const SizedBox(height: 20),
                _DetailRow(label: 'Phone', value: item.phone),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Role', value: item.role),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Member since', value: item.memberSince),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Submitted', value: item.submitted),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(
                  label: 'Status',
                  customValue: const _StatusPill(status: 'Pending'),
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
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => _showRejectDialog(item),
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
                  onPressed: () => _approveRequest(item),
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

  // ===========================================================================
  // A-2d · Owner request – rejected (ดูรายการที่ถูกปฏิเสธ เห็นเหตุผล ไม่มีปุ่ม Approve/Reject)
  // ===========================================================================
  Widget _buildDetailRejected(_OwnerRequestItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BreadcrumbHeader(
            parent: 'Owner requests',
            current: item.name,
            title: 'Owner request',
            onBack: _backToList,
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
                  child: Icon(
                    Icons.block,
                    size: 17,
                    color: Color(0xFFC92A2A),
                  ),
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
                _ApplicantHeader(
                  initials: item.initials,
                  name: item.name,
                  subtitle: 'Owner account',
                ),
                const SizedBox(height: 20),
                _DetailRow(label: 'Phone', value: item.phone),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Role', value: item.role),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Member since', value: item.memberSince),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Submitted', value: item.submitted),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(
                  label: 'Status',
                  customValue: const _StatusPill(status: 'Rejected'),
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
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF0062D6),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This request was rejected. The owner can edit their details and send a new request (D-150).',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
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

  // ===========================================================================
  // A-2e · Owner request – phone change (ขอเปลี่ยนเบอร์ล็อกอิน)
  // ===========================================================================
  Widget _buildDetailPhoneChange(_OwnerRequestItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BreadcrumbHeader(
            parent: 'Owner requests',
            current: 'Phone change · ${item.name}',
            title: 'Phone change request',
            onBack: _backToList,
          ),
          const SizedBox(height: 18),

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
                _ApplicantHeader(
                  initials: item.initials,
                  name: item.name,
                  subtitle: 'Phone change request',
                ),
                const SizedBox(height: 20),
                _DetailRow(label: 'Current phone', value: item.phone),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(
                  label: 'New phone',
                  value: item.newPhone ?? '081-999-0000',
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(
                  label: 'Account approved',
                  value: item.accountApprovedDate ?? '3 Sep 2026',
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(label: 'Submitted', value: item.submitted),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DetailRow(
                  label: 'Status',
                  customValue: const _StatusPill(status: 'Pending'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                    "Approving replaces this owner's sign-in number. Rejecting keeps the old number and sends the reason to the owner (D-163, D-166).",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => _showRejectDialog(item),
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
                  onPressed: () => _approveRequest(item),
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

class _OwnerRequestItem {
  const _OwnerRequestItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.phone,
    required this.role,
    required this.memberSince,
    required this.submitted,
    required this.documentName,
    required this.status,
    this.newPhone,
    this.accountApprovedDate,
    this.reviewedDate,
    this.rejectedTimestamp,
    this.rejectReason,
    this.isPhoneChange = false,
  });

  final String id;
  final String initials;
  final String name;
  final String phone;
  final String? newPhone;
  final String role;
  final String memberSince;
  final String? accountApprovedDate;
  final String submitted;
  final String? reviewedDate;
  final String? rejectedTimestamp;
  final String? rejectReason;
  final String documentName;
  final String status;
  final bool isPhoneChange;

  _OwnerRequestItem copyWith({
    String? status,
    String? reviewedDate,
    String? rejectedTimestamp,
    String? rejectReason,
  }) {
    return _OwnerRequestItem(
      id: id,
      initials: initials,
      name: name,
      phone: phone,
      newPhone: newPhone,
      role: role,
      memberSince: memberSince,
      accountApprovedDate: accountApprovedDate,
      submitted: submitted,
      documentName: documentName,
      status: status ?? this.status,
      reviewedDate: reviewedDate ?? this.reviewedDate,
      rejectedTimestamp: rejectedTimestamp ?? this.rejectedTimestamp,
      rejectReason: rejectReason ?? this.rejectReason,
      isPhoneChange: isPhoneChange,
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF0062D6) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF0062D6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (status == 'Rejected') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
    } else if (status == 'Approved') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _BreadcrumbHeader extends StatelessWidget {
  const _BreadcrumbHeader({
    required this.parent,
    required this.current,
    required this.title,
    required this.onBack,
  });

  final String parent;
  final String current;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: onBack,
              child: Text(
                parent,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const Text(
              ' / ',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            Text(
              current,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ApplicantHeader extends StatelessWidget {
  const _ApplicantHeader({
    required this.initials,
    required this.name,
    required this.subtitle,
  });

  final String initials;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0062D6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.customValue,
  });

  final String label;
  final String? value;
  final Widget? customValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: customValue ??
              Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
        ),
      ],
    );
  }
}

class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}