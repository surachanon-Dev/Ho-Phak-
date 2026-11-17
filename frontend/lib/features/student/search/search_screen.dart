import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/student/search/dorm_search_controller.dart';
import 'package:hopak_frontend/features/student/widgets/student_widgets.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/shared/widgets/dorm_card.dart';
import 'package:hopak_frontend/features/student/dorm_detail/student_dorm_detail_screen.dart';

/// ค้นหาและกรองหอพัก (หน้าตาตาม Frontend-Big): ช่องค้นหา + ปุ่มตัวกรอง (ราคา, ห้องว่าง),
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

  /// bottom sheet ตัวกรอง: ช่วงราคา และเฉพาะหอที่มีห้องว่าง
  Future<void> _openFilters() async {
    final f = _c.filters;
    final minC = TextEditingController(text: f.minPriceText);
    final maxC = TextEditingController(text: f.maxPriceText);
    var roomsOnly = f.roomsOnly;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตัวกรอง',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('ค่าเช่าต่อเดือน (บาท)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'ต่ำสุด'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: maxC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'สูงสุด'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('แสดงเฉพาะหอที่มีห้องว่าง'),
                  value: roomsOnly,
                  onChanged: (v) => setSheet(() => roomsOnly = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          minC.clear();
                          maxC.clear();
                          roomsOnly = false;
                          Navigator.of(ctx).pop(true);
                        },
                        child: const Text('ล้างค่า'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('ใช้ตัวกรอง'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final minText = minC.text;
    final maxText = maxC.text;
    minC.dispose();
    maxC.dispose();
    if (apply != true) return;
    _c.setMinPrice(minText);
    _c.setMaxPrice(maxText);
    _c.setRoomsOnly(roomsOnly);
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final f = _c.filters;
    final activeFilters =
        (f.minPriceText.trim().isNotEmpty || f.maxPriceText.trim().isNotEmpty
            ? 1
            : 0) +
        (f.roomsOnly ? 1 : 0);
    return Scaffold(
      appBar: AppBar(title: const Text('ค้นหาหอพัก'), actions: widget.actions),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onChanged: _c.setQuery,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหอพัก...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'ตัวกรอง',
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
                  tooltip: 'เรียงลำดับ',
                  onSelected: (s) {
                    _c.setSort(s);
                    _search();
                  },
                  itemBuilder: (_) => [
                    for (final e in DormSearchController.allSortLabels.entries)
                      PopupMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.sort, size: 18),
                    label: Text(
                      DormSearchController.allSortLabels[f.sort] ?? 'เรียง',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ทุกโซน'),
                  selected: f.zone == null,
                  onSelected: (_) {
                    _c.setZone(null);
                    _search();
                  },
                ),
                for (final z in dormZones) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(z),
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
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'พบ ${_c.items.length} หอพัก',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (_c.loading) const LinearProgressIndicator(),
          Expanded(
            child: _c.loading && _c.items.isEmpty
                ? const SizedBox.shrink()
                : _c.items.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    message: 'ไม่พบหอพัก',
                    detail: 'ลองเปลี่ยนคำค้นหาหรือเงื่อนไขการกรอง',
                    action: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('ล้างตัวกรอง'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _search,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _c.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => DormCard(
                        dorm: _c.items[i],
                        onTap: () => _openDorm(_c.items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
