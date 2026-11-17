import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/student/controllers/dorm_search_controller.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/shared/widgets/dorm_card.dart';
import 'package:hopak_frontend/shared/widgets/dorm_map.dart';
import 'package:hopak_frontend/features/student/screens/student_dorm_detail_screen.dart';

/// ค้นหาและกรองหอพัก: ชื่อ, โซน, ช่วงราคา, ห้องว่างเท่านั้น, และการเรียงลำดับ
/// ตรรกะทั้งหมดอยู่ใน [DormSearchController]
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.services, this.myUserId = 0});

  final AppServices services;
  final int myUserId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final DormSearchController _c;
  final _query = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  bool _showMap = false;

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
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final ok = await _c.search();
    if (!ok && _c.error != null && mounted) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _reset() async {
    _query.clear();
    _minPrice.clear();
    _maxPrice.clear();
    final ok = await _c.reset();
    if (!ok && _c.error != null && mounted) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  void _openDorm(int id) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentDormDetailScreen(
        services: widget.services,
        dormitoryId: id,
        myUserId: widget.myUserId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final f = _c.filters;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาหอพัก'),
        actions: [
          IconButton(
            tooltip: _showMap ? 'แสดงเป็นรายการ' : 'แสดงบนแผนที่',
            icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onChanged: _c.setQuery,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหอพัก',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'ล้างการค้นหา',
                  icon: const Icon(Icons.restart_alt),
                  onPressed: _reset,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('ทุกโซน'),
                  selected: f.zone == null,
                  onSelected: (_) {
                    _c.setZone(null);
                    _search();
                  },
                ),
                const SizedBox(width: 8),
                for (final z in dormZones) ...[
                  ChoiceChip(
                    label: Text(z),
                    selected: f.zone == z,
                    onSelected: (_) {
                      _c.setZone(z);
                      _search();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ราคาต่ำสุด',
                      isDense: true,
                    ),
                    onChanged: _c.setMinPrice,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ราคาสูงสุด',
                      isDense: true,
                    ),
                    onChanged: _c.setMaxPrice,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: f.sort,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final e in DormSearchController.sortLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    _c.setSort(v);
                    _search();
                  },
                ),
              ],
            ),
          ),
          if (_c.filterError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _c.filterError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('แสดงเฉพาะหอที่มีห้องว่าง'),
            value: f.roomsOnly,
            onChanged: (v) {
              _c.setRoomsOnly(v);
              _search();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _showMap
                ? DormMarkersMap(dorms: _c.items, onSelect: (d) => _openDorm(d.id))
                : _c.loading && _c.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _c.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('ไม่พบหอพัก'),
                        const SizedBox(height: 4),
                        const Text(
                          'ลองเปลี่ยนคำค้นหาหรือเงื่อนไขการกรอง',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _reset,
                          child: const Text('ล้างตัวกรอง'),
                        ),
                      ],
                    ),
                  )
                : GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                    children: [
                      for (final d in _c.items)
                        DormCard(dorm: d, onTap: () => _openDorm(d.id)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
