import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/admin_user_detail_controller.dart';
import '../../users/controller/admin_users_controller.dart';
import '../../../../services/admin_service.dart';
import '../../../../core/app_services.dart';
import '../../../../app/session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/admin_page.dart';

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
    final canSubmit =
        _controller.text.trim().isNotEmpty &&
        length <= AdminUsersController.maxReasonLength;
    return AlertDialog(
      icon: const IconBadge(icon: Icons.block, tone: Tone.danger, size: 44),
      title: Text('Suspend ${widget.name}?', textAlign: TextAlign.center),
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
      return EmptyState(
        icon: Icons.person_off_outlined,
        tone: Tone.neutral,
        title: _c.notFound
            ? 'This user no longer exists.'
            : 'Could not load this user.',
        action: TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to users'),
        ),
      );
    }

    final pad = adminPagePadding(context);
    final wide = isWideLayout(context);
    final info = _infoCard();
    final dorms = _c.isOwner ? _dormsCard() : null;

    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        ContentWidth(
          maxWidth: 1100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to users'),
                ),
              ),
              const SizedBox(height: 8),
              _profileHeader(),
              const SizedBox(height: 16),
              if (_c.isSuspended) ...[
                _suspendedBanner(),
                const SizedBox(height: 16),
              ],
              if (wide && dorms != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    Expanded(child: dorms),
                  ],
                )
              else ...[
                info,
                if (dorms != null) ...[const SizedBox(height: 16), dorms],
              ],
              const SizedBox(height: 16),
              _actionBar(wide),
              if (!_c.isAdmin) ...[
                const SizedBox(height: 16),
                _resetPasswordCard(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Tone get _roleTone => switch (_c.role) {
    'Owner' => Tone.primary,
    'Admin' => Tone.warning,
    _ => Tone.info,
  };

  Widget _profileHeader() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _c.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _c.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ToneBadge(label: _c.role, tone: _roleTone),
                    ToneBadge(
                      label: _c.status,
                      tone: _c.isSuspended ? Tone.danger : Tone.success,
                      solid: _c.isSuspended,
                    ),
                    if (_c.isOwner && _c.isVerified)
                      const ToneBadge(
                        label: 'Verified',
                        tone: Tone.success,
                        icon: Icons.verified_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _suspendedBanner() {
    final when = _c.suspendedAt;
    final reason = _c.suspensionReason;
    return NoticeBanner(
      tone: Tone.danger,
      icon: Icons.block,
      title: 'Account suspended by Admin',
      message: [
        if (when != null) 'On $when',
        if (reason != null && reason.isNotEmpty) 'Reason: $reason',
        'Sign-in is blocked',
      ].join(' · '),
    );
  }

  Widget _infoCard() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Account', icon: Icons.person_outline),
          const SizedBox(height: 6),
          InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: _c.phone),
          if (_c.isOwner) ...[
            const Divider(),
            InfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Verified owner',
              value: _c.isVerified ? 'Yes' : 'Not verified',
            ),
          ],
          const Divider(),
          InfoRow(
            icon: Icons.event_outlined,
            label: 'Joined',
            value: _c.joined,
          ),
        ],
      ),
    );
  }

  Widget _dormsCard() {
    final dorms = _c.dorms;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Dorms (${dorms.length})',
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 8),
          if (dorms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'This owner has no dorms yet.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            for (final (i, d) in dorms.indexed) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const IconBadge(
                      icon: Icons.apartment_rounded,
                      tone: Tone.neutral,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (d['name'] ?? '-').toString(),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    _dormStatusBadge((d['status'] ?? '').toString()),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  /// ผู้ใช้ลืมรหัสผ่าน: สร้างรหัสชั่วคราวให้แอดมินแจ้งผู้ใช้
  Widget _resetPasswordCard() {
    const info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: Icons.key_rounded, tone: Tone.violet),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forgot password',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Create a temporary password and give it to the user. '
                'They should change it after signing in.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
    final button = OutlinedButton.icon(
      onPressed: _c.busy ? null : _resetPassword,
      icon: const Icon(Icons.lock_reset_rounded, size: 18),
      label: const Text('Reset password'),
    );
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        // จอแคบ: ปุ่มอยู่ใต้ข้อความ จอกว้าง: ปุ่มอยู่ด้านขวา
        builder: (context, c) => c.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, const SizedBox(height: 14), button],
              )
            : Row(
                children: [
                  const Expanded(child: info),
                  const SizedBox(width: 12),
                  button,
                ],
              ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password?'),
        content: Text(
          'The current password of ${_c.displayName} will stop working. '
          'You will get a temporary password to give them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final temporary = await _c.resetPassword();
    if (!mounted) return;
    if (temporary == null) {
      _report();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const IconBadge(
          icon: Icons.check_rounded,
          tone: Tone.success,
          size: 48,
        ),
        title: const Text('Temporary password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give this password to the user. It is shown only once.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: SelectableText(
                temporary,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: temporary));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Copied')));
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _actionBar(bool wide) {
    final explanation = _c.isSuspended
        ? 'Lifting the suspension lets this account sign in again. Their dorms keep their current status.'
        : _c.isAdmin
        ? 'Admin accounts cannot be suspended from here.'
        : _c.isOwner
        ? 'Suspending blocks sign-in only. Their dorms keep their status — suspend a dorm separately if needed.'
        : 'Suspending blocks sign-in only. Their reviews and favourites stay.';

    Widget? button;
    if (_c.isSuspended) {
      button = FilledButton.icon(
        onPressed: _c.busy ? null : _lift,
        icon: const Icon(Icons.lock_open_rounded, size: 18),
        label: const Text('Lift suspension'),
      );
    } else if (_c.canSuspend) {
      button = OutlinedButton.icon(
        onPressed: _c.busy ? null : _suspend,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: Color(0xFFF3B4B4)),
        ),
        icon: const Icon(Icons.block, size: 18),
        label: const Text('Suspend account'),
      );
    }

    final text = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.info),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            explanation,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textBody,
              height: 1.45,
            ),
          ),
        ),
      ],
    );

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: wide || button == null
          ? Row(
              children: [
                Expanded(child: text),
                if (button != null) ...[const SizedBox(width: 16), button],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 14), button],
            ),
    );
  }

  static Widget _dormStatusBadge(String status) {
    final (label, tone, solid) = switch (status) {
      'published' => ('Published', Tone.success, false),
      'pending' => ('Pending review', Tone.warning, false),
      'changes_pending' => ('Changes pending', Tone.violet, false),
      'suspended' => ('Suspended', Tone.danger, true),
      'rejected' => ('Rejected', Tone.danger, false),
      'hidden' => ('Hidden', Tone.neutral, false),
      'draft' => ('Draft', Tone.neutral, false),
      _ => (status.isEmpty ? '-' : status, Tone.neutral, false),
    };
    return ToneBadge(label: label, tone: tone, solid: solid);
  }
}
