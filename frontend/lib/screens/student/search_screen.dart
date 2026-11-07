import 'package:flutter/material.dart';

import '../../models/dormitory.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../../widgets/dorm_card.dart';
import '../../widgets/dorm_map.dart';
import 'student_dorm_detail_screen.dart';

/// ค้นหาและกรองหอพัก: ชื่อ, โซน, ช่วงราคา, ห้องว่างเท่านั้น, และการเรียงลำดับ
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.services, this.myUserId = 0});

  final AppServices services;
  final int myUserId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  String? _zone;
  bool _roomsOnly = false;
  String _sort = 'newest';
  List<Dormitory> _items = [];
  bool _loading = false;
  bool _showMap = false;

  static const _sorts = {
    'newest': 'ใหม่ล่าสุด',
    'price_asc': 'ราคาต่ำไปสูง',
    'price_desc': 'ราคาสูงไปต่ำ',
  };

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final items = await widget.services.publicDorms.search(
        zone: _zone,
        query: _query.text,
        minPrice: int.tryParse(_minPrice.text.trim()),
        maxPrice: int.tryParse(_maxPrice.text.trim()),
        roomsOnly: _roomsOnly,
        sort: _sort,
      );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _query.clear();
      _minPrice.clear();
      _maxPrice.clear();
      _zone = null;
      _roomsOnly = false;
      _sort = 'newest';
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
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
                  selected: _zone == null,
                  onSelected: (_) {
                    setState(() => _zone = null);
                    _search();
                  },
                ),
                const SizedBox(width: 8),
                for (final z in dormZones) ...[
                  ChoiceChip(
                    label: Text(z),
                    selected: _zone == z,
                    onSelected: (_) {
                      setState(() => _zone = z);
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
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final e in _sorts.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    setState(() => _sort = v ?? _sort);
                    _search();
                  },
                ),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('แสดงเฉพาะหอที่มีห้องว่าง'),
            value: _roomsOnly,
            onChanged: (v) {
              setState(() => _roomsOnly = v);
              _search();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _showMap
                ? DormMarkersMap(
                    dorms: _items,
                    onSelect: (d) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentDormDetailScreen(
                          services: widget.services,
                          dormitoryId: d.id,
                          myUserId: widget.myUserId,
                        ),
                      ),
                    ),
                  )
                : _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
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
                      for (final d in _items)
                        DormCard(
                          dorm: d,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentDormDetailScreen(
                                services: widget.services,
                                dormitoryId: d.id,
                                myUserId: widget.myUserId,
                              ),
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
