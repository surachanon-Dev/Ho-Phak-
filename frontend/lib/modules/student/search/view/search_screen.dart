import 'package:flutter/material.dart';

import '../../../../app/session.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../model/amenity.dart';
import '../../../../model/dormitory.dart';
import '../../../../widgets/dorm_card.dart';
import '../../../../widgets/ui/ui.dart';
import '../controller/dorm_search_controller.dart';
import '../../widgets/student_ui.dart';
import '../../dorm_detail/view/student_dorm_detail_screen.dart';

/// ค้นหาและกรองหอพัก (ธีมโครงใหม่): ช่องค้นหา + ปุ่มตัวกรอง (ราคา, ห้องว่าง),
/// ชิปเรียงลำดับ, ชิปโซน และจำนวนผลลัพธ์ ตรรกะทั้งหมดอยู่ใน [DormSearchController]
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.services,
    this.myUserId = 0,
    this.actions,
  });

  final AppServices services;
  final int myUserId;

  /// ปุ่มบน app bar (แชท / แจ้งเตือน) เมื่ออยู่ในแท็บของ StudentShell
  final List<Widget>? actions;

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  late final DormSearchController _c;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = DormSearchController(widget.services.publicDorms);
    _c.addListener(_onChanged);
    _search();
    _c.loadAmenities();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _query.dispose();
    super.dispose();
  }

  void _showError() {
    if (_c.error != null && mounted) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _search() async {
    final ok = await _c.search();
    if (!ok) _showError();
  }

  /// เรียกจากหน้าแรก (กดชิปโซน หรือ "ดูทั้งหมด")
  Future<void> applyQuick({String? zone, String? sort}) async {
    _query.clear();
    final ok = await _c.applyQuick(zone: zone, sort: sort);
    if (!ok) _showError();
  }

  Future<void> _reset() async {
    _query.clear();
    final ok = await _c.reset();
    if (!ok) _showError();
  }

  void _openDorm(Dormitory d) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentDormDetailScreen(
        services: widget.services,
        dormitoryId: d.id,
        myUserId: widget.myUserId,
      ),
    ),
  );

  /// bottom sheet ตัวกรอง: ช่วงราคา, เฉพาะหอที่มีห้องว่าง และสิ่งอำนวยความสะดวก
  /// ช่องกรอกอยู่ใน [_FilterSheet] ที่ดูแล TextEditingController เอง
  /// (กันปัญหาใช้ controller ที่ dispose แล้วระหว่างที่ sheet กำลังเลื่อนปิด)
  Future<void> _openFilters() async {
    await _c.loadAmenities(); // ปกติโหลดไว้แล้วตั้งแต่เปิดหน้า
    if (!mounted) return;
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _c.filters, amenities: _c.amenities),
    );
    if (result == null || !mounted) return;
    _c.setMinPrice(result.minPriceText);
    _c.setMaxPrice(result.maxPriceText);
    _c.setRoomsOnly(result.roomsOnly);
    _c.setAmenities(result.amenityIds);
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final f = _c.filters;
    final activeFilters =
        (f.minPriceText.trim().isNotEmpty || f.maxPriceText.trim().isNotEmpty
            ? 1
            : 0) +
        (f.roomsOnly ? 1 : 0) +
        (f.amenityIds.isNotEmpty ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        // อยู่ในแท็บของ StudentShell (มี actions) ไม่ต้องมีปุ่มย้อนกลับ
        automaticallyImplyLeading: widget.actions == null,

        title: const Text('Search dorms'),
        actions: widget.actions,
      ),
      body: Column(
        children: [
          StudentBody(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onChanged: _c.setQuery,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search by dorm name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Filters',
                        icon: Badge(
                          isLabelVisible: activeFilters > 0,
                          label: Text('$activeFilters'),
                          child: const Icon(Icons.tune),
                        ),
                        onPressed: _openFilters,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      PopupMenuButton<String>(
                        initialValue: f.sort,
                        tooltip: 'Sort',
                        onSelected: (s) {
                          _c.setSort(s);
                          _search();
                        },
                        itemBuilder: (_) => [
                          for (final e
                              in DormSearchController.allSortLabels.entries)
                            PopupMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        child: Chip(
                          backgroundColor: AppColors.primarySoft,
                          side: BorderSide.none,
                          avatar: const Icon(
                            Icons.swap_vert_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            DormSearchController.allSortLabels[f.sort] ??
                                'Sort',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All zones'),
                        selected: f.zone == null,
                        onSelected: (_) {
                          _c.setZone(null);
                          _search();
                        },
                      ),
                      for (final z in dormZones) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(zoneLabel(z)),
                          selected: f.zone == z,
                          onSelected: (_) {
                            _c.setZone(z);
                            _search();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (_c.filterError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _c.filterError!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ToneBadge(
                      label: '${_c.items.length} dorms found',
                      tone: Tone.primary,
                      icon: Icons.apartment_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (_c.loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _c.loading && _c.items.isEmpty
                ? const SizedBox.shrink()
                : _c.items.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No dorms found',
                    message: 'Try a different search or change the filters.',
                    action: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Clear filters'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _search,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: _c.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => StudentBody(
                        child: DormCard(
                          dorm: _c.items[i],
                          onTap: () => _openDorm(_c.items[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// เนื้อหา bottom sheet ตัวกรอง: ปิดด้วย SearchFilters ที่เลือก (null = ปิดเฉยๆ ไม่เปลี่ยนอะไร)
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.amenities});

  final SearchFilters initial;
  final List<Amenity> amenities;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final _min = TextEditingController(text: widget.initial.minPriceText);
  late final _max = TextEditingController(text: widget.initial.maxPriceText);
  late bool _roomsOnly = widget.initial.roomsOnly;
  late final Set<int> _picked = Set<int>.of(widget.initial.amenityIds);

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _close({required bool reset}) => Navigator.of(context).pop(
    widget.initial.copyWith(
      minPriceText: reset ? '' : _min.text,
      maxPriceText: reset ? '' : _max.text,
      roomsOnly: reset ? false : _roomsOnly,
      amenityIds: reset ? <int>{} : Set<int>.of(_picked),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text('Monthly rent (baht)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Min'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Only dorms with free rooms'),
              value: _roomsOnly,
              onChanged: (v) => setState(() => _roomsOnly = v),
            ),
            if (widget.amenities.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text('Amenities'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in widget.amenities)
                    FilterChip(
                      key: ValueKey('amenity_${a.id}'),
                      label: Text(a.name),
                      selected: _picked.contains(a.id),
                      onSelected: (v) => setState(
                        () => v ? _picked.add(a.id) : _picked.remove(a.id),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _close(reset: true),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _close(reset: false),
                    child: const Text('Apply'),
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
