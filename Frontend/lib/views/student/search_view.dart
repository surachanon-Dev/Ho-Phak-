import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import '../../services/dorm_service.dart';
import '../widgets/common.dart';
import '../widgets/dorm_card.dart';
import 'dorm_detail_view.dart';

const _sorts = {'newest': 'ล่าสุด', 'price_asc': 'ราคาต่ำ-สูง', 'price_desc': 'ราคาสูง-ต่ำ', 'rating': 'คะแนนรีวิว', 'distance': 'ใกล้มหาวิทยาลัย'};

/// Search published dorms: keyword, zone (enum), price range, available rooms, amenities, sort
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => SearchViewState();
}

class SearchViewState extends State<SearchView> {
  final _q = TextEditingController();
  DormFilter _filter = const DormFilter();
  List<Dormitory> _items = [];
  List<Amenity> _amenities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
    context.read<DormService>().amenities().then((a) {
      if (mounted) setState(() => _amenities = a);
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  /// Called from Home (zone chip / "ดูทั้งหมด")
  void applyQuick({String? zone, String? sort}) {
    _filter = DormFilter(zone: zone, sort: sort ?? 'newest');
    _q.clear();
    _search();
  }

  Future<void> _search([DormFilter? f]) async {
    if (f != null) _filter = f;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<DormService>().search(_filter);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFilters() async {
    final minC = TextEditingController(text: _filter.minPrice?.toString() ?? '');
    final maxC = TextEditingController(text: _filter.maxPrice?.toString() ?? '');
    final picked = Set<int>.of(_filter.amenityIds);
    final result = await showModalBottomSheet<DormFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ตัวกรอง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('ค่าเช่าต่อเดือน (บาท)'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: minC, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ต่ำสุด'))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                Expanded(child: TextField(controller: maxC, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'สูงสุด'))),
              ]),
              const SizedBox(height: 16),
              const Text('สิ่งอำนวยความสะดวก'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final a in _amenities)
                  FilterChip(
                    label: Text(a.name),
                    selected: picked.contains(a.id),
                    onSelected: (v) => setSheet(() => v ? picked.add(a.id) : picked.remove(a.id)),
                  ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, DormFilter(q: _filter.q, zone: _filter.zone, sort: _filter.sort)),
                    child: const Text('ล้างตัวกรอง'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      DormFilter(
                        q: _filter.q,
                        zone: _filter.zone,
                        sort: _filter.sort,
                        minPrice: int.tryParse(minC.text),
                        maxPrice: int.tryParse(maxC.text),
                        amenityIds: picked.toList(),
                      ),
                    ),
                    child: const Text('ใช้ตัวกรอง'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (result != null) _search(result);
  }

  @override
  Widget build(BuildContext context) {
    final f = _filter;
    final active = (f.minPrice != null || f.maxPrice != null ? 1 : 0) + (f.amenityIds.isNotEmpty ? 1 : 0);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          controller: _q,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อหอพัก ที่อยู่ โซน...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Badge(isLabelVisible: active > 0, label: Text('$active'), child: const Icon(Icons.tune)),
              onPressed: _openFilters,
            ),
          ),
          onSubmitted: (v) => _search(f.copyWith(q: v)),
        ),
      ),
      SizedBox(
        height: 48,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          PopupMenuButton<String>(
            initialValue: f.sort,
            onSelected: (s) => _search(f.copyWith(sort: s)),
            itemBuilder: (_) => [for (final e in _sorts.entries) PopupMenuItem(value: e.key, child: Text(e.value))],
            child: Chip(avatar: const Icon(Icons.sort, size: 18), label: Text(_sorts[f.sort] ?? 'เรียง')),
          ),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('ทุกโซน'), selected: f.zone == null, onSelected: (_) => _search(f.copyWith(clearZone: true))),
          for (final z in AppConfig.zones) ...[
            const SizedBox(width: 8),
            ChoiceChip(label: Text(z), selected: f.zone == z, onSelected: (_) => _search(f.copyWith(zone: z))),
          ],
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(alignment: Alignment.centerLeft, child: Text('พบ ${_items.length} หอพัก', style: const TextStyle(color: AppColors.muted, fontSize: 13))),
      ),
      if (_loading) const LinearProgressIndicator(),
      Expanded(
        child: _error != null
            ? ErrorRetry(message: _error!, onRetry: _search)
            : _items.isEmpty && !_loading
                ? const EmptyState(icon: Icons.search_off, message: 'ไม่พบหอพักที่ตรงกับเงื่อนไข')
                : RefreshIndicator(
                    onRefresh: _search,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => DormCard(
                        dorm: _items[i],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DormDetailView(dormId: _items[i].id))),
                      ),
                    ),
                  ),
      ),
    ]);
  }
}
