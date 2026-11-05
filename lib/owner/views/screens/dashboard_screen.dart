import 'package:flutter/material.dart';

import '../../controller/owner_controller.dart';
import '../../controller/owner_session.dart';
import '../../models/dormitory.dart';
import '../../models/dormitory_details.dart';
import '../theme/owner_theme.dart';
import '../utils/formatters.dart';
import '../widgets/page_frame.dart';
import '../widgets/small_parts.dart';
import '../widgets/surface_card.dart';
import 'dormitory_detail_screen.dart';
import 'dormitory_form_screen.dart';

/// หน้าหลัก: สรุปจำนวนหอ กรองตามสถานะ และรายการหอของเจ้าของ
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Dormitory>? _items;
  DormitoryStatus? _filter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await OwnerController.fetchDormitories();
    if (mounted) setState(() => _items = items);
  }

  /// เปิดฟอร์มเพิ่มหอ (ไม่ส่งอะไร) หรือแก้ไข (ส่งหอที่จะแก้) บันทึกแล้วโหลดรายการใหม่
  Future<void> openForm([Dormitory? dormitory]) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => DormitoryFormScreen(dormitory: dormitory)));
    if (saved == true) _reload();
  }

  Future<void> _openDetail(Dormitory dormitory) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => DormitoryDetailScreen(dormitory: dormitory)));
    if (changed == true) _reload();
  }

  void _togglePublished(Dormitory d, bool value) {
    final details = OwnerSession.detailsOf(d.id);
    setState(() => OwnerSession.saveDetails(d.id, details.withPublished(value)));
  }

  static const _titles = {
    null: 'หอทั้งหมด',
    DormitoryStatus.approved: 'หอที่อนุมัติแล้ว',
    DormitoryStatus.pending: 'หอที่รอตรวจสอบ',
    DormitoryStatus.rejected: 'หอที่ไม่ผ่าน',
  };

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final all = items ?? const <Dormitory>[];
    DormitoryStatus statusOf(Dormitory d) => OwnerSession.detailsOf(d.id).status;
    final visible = all.where((d) => _filter == null || statusOf(d) == _filter).toList();

    final counts = items == null
        ? null
        : <DormitoryStatus?, int>{
            null: all.length,
            for (final s in DormitoryStatus.values) s: all.where((d) => statusOf(d) == s).length,
          };

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(
          counts: counts,
          filter: _filter,
          onFilter: (s) => setState(() => _filter = s),
          onOpenProfile: widget.onOpenProfile,
        ),
        PageFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 14, OwnerGap.page, OwnerGap.belowNav),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          _titles[_filter]!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700, color: OwnerColors.navy),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => openForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('เพิ่มหอ'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (items == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (all.isEmpty)
                  _Notice(message: 'ยังไม่มีหอพัก กดปุ่มเพิ่มหอเพื่อเริ่มต้น', actionLabel: 'เพิ่มหอ', onAction: () => openForm())
                else if (visible.isEmpty)
                  const _Notice(message: 'ไม่มีหอในสถานะนี้')
                else
                  for (final d in visible) ...[
                    _DormitoryCard(
                      dormitory: d,
                      details: OwnerSession.detailsOf(d.id),
                      onOpen: () => _openDetail(d),
                      onEdit: () => openForm(d),
                      onPublishChanged: (v) => _togglePublished(d, v),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.counts, required this.filter, required this.onFilter, required this.onOpenProfile});

  final Map<DormitoryStatus?, int>? counts;
  final DormitoryStatus? filter;
  final ValueChanged<DormitoryStatus?> onFilter;
  final VoidCallback onOpenProfile;

  static const _tiles = <(String, DormitoryStatus?)>[
    ('ทั้งหมด', null),
    ('อนุมัติ', DormitoryStatus.approved),
    ('รอตรวจ', DormitoryStatus.pending),
    ('ไม่ผ่าน', DormitoryStatus.rejected),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = OwnerSession.username;
    const muted = Color(0xFFC9D6E0);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: OwnerColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(OwnerRadius.header)),
      ),
      child: SafeArea(
        bottom: false,
        child: PageFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 8, OwnerGap.page, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Ho-Phak',
                        style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Pill('Owner', color: OwnerColors.navy),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: 'โปรไฟล์ $name',
                      child: ExcludeSemantics(
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onOpenProfile,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: OwnerColors.primary,
                            child: Text(
                              firstLetter(name),
                              style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name.isEmpty ? 'สวัสดี' : 'สวัสดี คุณ$name', style: text.bodySmall?.copyWith(color: muted)),
                Text('หอพักของฉัน',
                    style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < _tiles.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _CountTile(
                          label: _tiles[i].$1,
                          count: counts == null ? '–' : '${counts![_tiles[i].$2] ?? 0}',
                          selected: filter == _tiles[i].$2,
                          onTap: () => onFilter(_tiles[i].$2),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final String count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: text.titleLarge?.copyWith(
                      color: selected ? OwnerColors.navy : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      color: selected ? OwnerColors.textMuted : const Color(0xFFC9D6E0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: OwnerColors.textBody),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DormitoryCard extends StatelessWidget {
  const _DormitoryCard({
    required this.dormitory,
    required this.details,
    required this.onOpen,
    required this.onEdit,
    required this.onPublishChanged,
  });

  final Dormitory dormitory;
  final DormitoryDetails details;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final ValueChanged<bool> onPublishChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rooms = details.availableRooms;
    final canPublish = details.approved;
    final hint = !canPublish
        ? 'เปิดได้เมื่อหออนุมัติแล้ว'
        : details.published
            ? 'นักศึกษาค้นเจอหอนี้'
            : 'ซ่อนจากการค้นหาอยู่';

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(OwnerRadius.tile),
            onTap: onOpen,
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: OwnerColors.photo,
                    borderRadius: BorderRadius.circular(OwnerRadius.tile),
                  ),
                  child: const Icon(Icons.apartment, color: OwnerColors.textMuted, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dormitory.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(details.status),
                        ],
                      ),
                      Text.rich(
                        TextSpan(
                          text: dormitory.zone,
                          children: [
                            if (rooms != null)
                              TextSpan(
                                text: rooms > 0 ? ' · ว่าง $rooms ห้อง' : ' · เต็ม',
                                style: TextStyle(
                                  color: rooms > 0 ? OwnerColors.textMuted : OwnerColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                      ),
                      Text(
                        '${withCommas(dormitory.pricePerMonth)} บาท/เดือน',
                        style: text.titleSmall?.copyWith(color: OwnerColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: MiniStat(label: 'ค่าน้ำ', value: details.waterText)),
              const SizedBox(width: 6),
              Expanded(child: MiniStat(label: 'ค่าไฟ', value: details.electricText)),
              const SizedBox(width: 6),
              Expanded(child: MiniStat(label: 'มัดจำ', value: details.depositText)),
            ],
          ),
          if (details.amenities.isNotEmpty) ...[
            const SizedBox(height: 10),
            AmenityWrap(details.amenities),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: OwnerColors.textMuted),
              const SizedBox(width: 4),
              Text('ปักหมุดแล้ว', style: text.bodySmall?.copyWith(color: OwnerColors.textMuted)),
            ],
          ),
          if (details.status == DormitoryStatus.rejected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: OwnerColors.dangerTint,
                borderRadius: BorderRadius.circular(OwnerRadius.tile),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เหตุผลที่ไม่ผ่าน',
                      style: text.bodySmall?.copyWith(color: OwnerColors.danger, fontWeight: FontWeight.w600)),
                  Text(details.rejectReason ?? 'ไม่ได้ระบุเหตุผล',
                      style: text.bodySmall?.copyWith(color: OwnerColors.danger)),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: OwnerColors.danger, padding: EdgeInsets.zero),
                    onPressed: onEdit,
                    child: const Text('แก้ไขแล้วส่งตรวจใหม่'),
                  ),
                ],
              ),
            ),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เปิดให้หาเจอ', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(hint, style: text.bodySmall?.copyWith(color: OwnerColors.textMuted)),
                  ],
                ),
              ),
              Semantics(
                label: 'เปิดให้หาเจอ ${dormitory.name}',
                child: Switch(value: canPublish && details.published, onChanged: canPublish ? onPublishChanged : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
