import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/session.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/status_style.dart';
import '../../../shared/widgets/document_viewer.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../owner_requests/widgets/owner_request_widgets.dart';
import '../services/admin_service.dart';
import '../widgets/admin_page.dart';
import '../widgets/reason_dialog.dart';
import 'admin_dorms_controller.dart';

/// หน้า Dorms ของแอดมิน (เมนู Dorms)
/// - Awaiting review: หอใหม่และฉบับแก้ไขที่รอตรวจ อนุมัติ/ปฏิเสธ
/// - All dorms: หอทั้งหมด กรองตามสถานะ ระงับ/ยกเลิกการระงับ
class AdminDormsTab extends StatefulWidget {
  const AdminDormsTab({super.key, required this.services, this.onChanged});

  final AppServices services;

  /// เรียกหลังการเปลี่ยนแปลงสำเร็จ เพื่อให้ badge เมนูและแดชบอร์ดโหลดตัวเลขใหม่
  final VoidCallback? onChanged;

  @override
  State<AdminDormsTab> createState() => _AdminDormsTabState();
}

class _AdminDormsTabState extends State<AdminDormsTab> {
  late final AdminDormsController _c;

  /// 0 = Awaiting review, 1 = All dorms
  int _tab = 0;

  static const _statusFilters = <String?, String>{
    null: 'All statuses',
    'published': 'Published',
    'hidden': 'Hidden',
    'suspended': 'Suspended',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _c = AdminDormsController(AdminService(widget.services.api));
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.refreshAll();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _report(bool ok) {
    if (!mounted) return;
    if (ok) {
      widget.onChanged?.call();
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = RequestTabBar(
      children: [
        RequestTabButton(
          label: 'Awaiting review',
          count: _c.awaitingCount,
          selected: _tab == 0,
          onTap: () => setState(() => _tab = 0),
        ),
        RequestTabButton(
          label: 'All dorms',
          count: _c.allDormitories.length,
          selected: _tab == 1,
          onTap: () => setState(() => _tab = 1),
        ),
      ],
    );

    return AdminPage(
      title: 'Dorms',
      subtitle: 'Review new listings and edits, and moderate published dorms',
      actions: [
        HeaderIconButton(
          tooltip: 'Refresh',
          icon: Icons.refresh,
          onPressed: _c.loading ? null : () => _c.refreshAll(),
        ),
      ],
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tabs,
          if (_tab == 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in _statusFilters.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _c.statusFilter == e.key,
                        showCheckmark: false,
                        onSelected: (_) => _c.loadAll(status: e.key),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      child: _tab == 0 ? _awaitingList() : _allList(),
    );
  }

  Widget _awaitingList() {
    final rows = [
      for (final d in _c.newDormitories) (d, 'New dorm'),
      for (final r in _c.revisions) (r, 'Edit request'),
    ];
    if (_c.loading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt_rounded,
        tone: Tone.success,
        title: 'Nothing waiting for review',
        message: 'New dorms and edit requests from owners will appear here.',
      );
    }
    final wide = isWideLayout(context);
    return AdminListView(
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final (row, kind) = rows[i];
        final dormId = ((row['dormitory_id'] ?? row['id']) as num).toInt();
        final name = (row['name'] ?? row['dormitory_name'] ?? '-').toString();
        final zone = row['zone']?.toString();
        final owner = row['owner_username']?.toString();
        final isEdit = kind == 'Edit request';

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              style: _compact,
              onPressed: () => _viewDocument(dormId, name),
              icon: const Icon(Icons.description_outlined, size: 17),
              label: const Text('Document'),
            ),
            OutlinedButton(
              style: _compact.merge(
                OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: Color(0xFFF3B4B4)),
                ),
              ),
              onPressed: _c.busy ? null : () => _reject(dormId),
              child: const Text('Reject'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: _c.busy
                  ? null
                  : () async => _report(await _c.approve(dormId)),
              child: const Text('Approve'),
            ),
          ],
        );

        final info = _DormIdentity(
          name: name,
          icon: isEdit ? Icons.edit_note_rounded : Icons.add_home_outlined,
          tone: isEdit ? Tone.violet : Tone.primary,
          badge: ToneBadge(
            label: kind,
            tone: isEdit ? Tone.violet : Tone.primary,
          ),
          meta: [?zone, if (owner != null) 'by $owner'],
        );

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: wide
              ? Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [info, const SizedBox(height: 14), actions],
                ),
        );
      },
    );
  }

  static final _compact = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 14),
  );

  /// เปิดดูเอกสารความเป็นเจ้าของของหอ (ก่อนอนุมัติ)
  Future<void> _viewDocument(int dormId, String name) async {
    final Uint8List bytes;
    try {
      bytes = await AdminService(widget.services.api).dormitoryDocument(dormId);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
      return;
    }
    if (!mounted) return;
    await showDocumentViewer(context, name: name, bytes: bytes);
  }

  Future<void> _reject(int dormId) async {
    final reason = await showReasonDialog(
      context,
      title: 'Reject this dorm?',
      message: 'The owner will see this reason and can fix the listing.',
      confirmLabel: 'Reject',
      maxLength: AdminDormsController.maxReasonLength,
    );
    if (reason == null) return;
    _report(await _c.reject(dormId, reason));
  }

  Widget _allList() {
    if (_c.loading && _c.allDormitories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_c.allDormitories.isEmpty) {
      return const EmptyState(
        icon: Icons.apartment_outlined,
        tone: Tone.neutral,
        title: 'No dorms',
        message: 'No dorm matches this status.',
      );
    }
    return AdminListView(
      itemCount: _c.allDormitories.length,
      itemBuilder: (context, i) {
        final d = _c.allDormitories[i];
        final id = (d['id'] as num).toInt();
        final status = (d['status'] ?? '').toString();
        final suspended = status == 'suspended';
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _DormIdentity(
                  name: (d['name'] ?? '-').toString(),
                  icon: Icons.apartment_rounded,
                  tone: suspended ? Tone.danger : Tone.primary,
                  badge: StatusChip(displayStatus: status),
                  meta: [
                    '${d['zone'] ?? '-'}',
                    'owner ${d['owner_username'] ?? d['owner_id'] ?? '-'}',
                  ],
                ),
              ),
              const SizedBox(width: 10),
              suspended
                  ? FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: _c.busy
                          ? null
                          : () async => _report(await _c.restore(id)),
                      child: const Text('Restore'),
                    )
                  : OutlinedButton(
                      style: _compact,
                      onPressed: _c.busy ? null : () => _suspend(id),
                      child: const Text('Suspend'),
                    ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _suspend(int dormId) async {
    final reason = await showReasonDialog(
      context,
      title: 'Suspend this dorm?',
      message: 'Students will no longer see this dorm until it is restored.',
      confirmLabel: 'Suspend',
      icon: Icons.block,
      maxLength: AdminDormsController.maxReasonLength,
    );
    if (reason == null) return;
    _report(await _c.suspend(dormId, reason));
  }
}

class _DormIdentity extends StatelessWidget {
  const _DormIdentity({
    required this.name,
    required this.icon,
    required this.tone,
    required this.badge,
    required this.meta,
  });

  final String name;
  final IconData icon;
  final Tone tone;
  final Widget badge;
  final List<String> meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBadge(icon: icon, tone: tone, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  badge,
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meta.join(' · '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
