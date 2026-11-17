import 'package:flutter/material.dart';

import '../../controllers/admin_user_detail_controller.dart';
import '../../controllers/admin_users_controller.dart';
import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/error_handling.dart';

/// รายละเอียดผู้ใช้ 1 คน (เมนู Users → View): ข้อมูลบัญชี หอของเจ้าของ และการระงับ/ยกเลิกการระงับ
/// ไม่มี Scaffold เพราะแสดงอยู่ในพื้นที่เนื้อหาของหน้าแอดมิน
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({
    super.key,
    required this.services,
    required this.userId,
    required this.onBack,
  });

  final AppServices services;
  final int userId;

  /// กลับไปหน้ารายการผู้ใช้
  final VoidCallback onBack;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

/// กล่องถามเหตุผลการระงับ เป็น StatefulWidget เพื่อให้ controller ถูก dispose พร้อมกับกล่อง
class _SuspendReasonDialog extends StatefulWidget {
  const _SuspendReasonDialog({required this.name});

  final String name;

  @override
  State<_SuspendReasonDialog> createState() => _SuspendReasonDialogState();
}

class _SuspendReasonDialogState extends State<_SuspendReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    final canSubmit = _controller.text.trim().isNotEmpty &&
        length <= AdminUsersController.maxReasonLength;
    return AlertDialog(
      title: Text('Suspend ${widget.name}?'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: AdminUsersController.maxReasonLength,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Reason (required)',
          hintText: 'Why is this account being suspended?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          child: const Text('Suspend'),
        ),
      ],
    );
  }
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late final AdminUserDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = AdminUserDetailController(
      AdminService(widget.services.api),
      userId: widget.userId,
    );
    _c.addListener(_onChanged);
    _c.load().then((ok) {
      if (!ok && mounted && _c.error != null) {
        showApiError(context, widget.services, _c.error!);
      }
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _report() {
    if (mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _suspend() async {
    final reason = await _askReason();
    if (reason == null || !mounted) return;
    final ok = await _c.suspend(reason);
    if (!ok) _report();
  }

  Future<void> _lift() async {
    final ok = await _c.restore();
    if (!ok) _report();
  }

  /// ขอเหตุผลการระงับ (บังคับกรอก ไม่เกิน 300 ตัวอักษร) คืน null ถ้ายกเลิก
  Future<String?> _askReason() {
    return showDialog<String>(
      context: context,
      builder: (_) => _SuspendReasonDialog(name: _c.displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_c.user == null) {
      if (_c.loading) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return _emptyState(
        _c.notFound ? 'This user no longer exists.' : 'Could not load this user.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to users'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _c.displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          if (_c.isSuspended) ...[
            _suspendedBanner(),
            const SizedBox(height: 16),
          ],
          _infoCard(),
          if (_c.isOwner) ...[
            const SizedBox(height: 16),
            _dormsCard(),
          ],
          const SizedBox(height: 16),
          _actionBar(),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextButton(onPressed: widget.onBack, child: const Text('Back to users')),
        ],
      ),
    );
  }

  Widget _suspendedBanner() {
    final when = _c.suspendedAt;
    final reason = _c.suspensionReason;
    return Container(
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
            child: Text(
              [
                'Account suspended by Admin',
                if (when != null) 'on $when',
                if (reason != null && reason.isNotEmpty) 'Reason: $reason',
                'Sign-in is blocked',
              ].join(' · '),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFC92A2A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  _c.initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0062D6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(_c.role, _roleColors(_c.role)),
                    _pill(
                      _c.status,
                      _c.isSuspended
                          ? const (Color(0xFFC92A2A), Colors.white)
                          : const (Color(0xFFDCFCE7), Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _keyValue('Phone', _c.phone),
          if (_c.isOwner) ...[
            const Divider(height: 22, color: Color(0xFFF1F5F9)),
            _keyValue('Verified owner', _c.isVerified ? 'Yes' : 'Not verified'),
          ],
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          _keyValue('Joined', _c.joined),
        ],
      ),
    );
  }

  Widget _dormsCard() {
    final dorms = _c.dorms;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dorms (${dorms.length})',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (dorms.isEmpty)
            const Text(
              'This owner has no dorms yet.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            )
          else
            for (final d in dorms) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (d['name'] ?? '-').toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _pill(
                      _dormStatusLabel((d['status'] ?? '').toString()),
                      _dormStatusColors((d['status'] ?? '').toString()),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _actionBar() {
    final explanation = _c.isSuspended
        ? 'Lifting the suspension lets this account sign in again. Their dorms keep their current status.'
        : _c.isAdmin
            ? 'Admin accounts cannot be suspended from here.'
            : _c.isOwner
                ? 'Suspending blocks sign-in only. Their dorms keep their status — suspend a dorm separately if needed.'
                : 'Suspending blocks sign-in only. Their reviews and favourites stay.';

    return _card(
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF0062D6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              explanation,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(width: 16),
          if (_c.isSuspended)
            FilledButton(
              onPressed: _c.busy ? null : _lift,
              child: const Text('Lift suspension'),
            )
          else if (_c.canSuspend)
            OutlinedButton(
              onPressed: _c.busy ? null : _suspend,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC92A2A),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
              ),
              child: const Text('Suspend account'),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _keyValue(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
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

  Widget _pill(String text, (Color, Color) colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  static (Color, Color) _roleColors(String role) {
    switch (role) {
      case 'Owner':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case 'Admin':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  static (Color, Color) _dormStatusColors(String status) {
    switch (status) {
      case 'published':
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case 'pending':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case 'changes_pending':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case 'suspended':
        return (const Color(0xFFC92A2A), Colors.white);
      case 'rejected':
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  static String _dormStatusLabel(String status) {
    switch (status) {
      case 'published':
        return 'Published';
      case 'pending':
        return 'Pending review';
      case 'changes_pending':
        return 'Changes pending';
      case 'suspended':
        return 'Suspended';
      case 'rejected':
        return 'Rejected';
      case 'hidden':
        return 'Hidden';
      case 'draft':
        return 'Draft';
      default:
        return status.isEmpty ? '-' : status;
    }
  }
}
