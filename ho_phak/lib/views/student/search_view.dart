import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'dorm_detail_view.dart';
import 'filter_bottom_sheet.dart';
import 'map_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  RangeValues _priceRange = const RangeValues(1500, 15000);
  bool _hasAc = true;
  bool _hasWifi = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialPriceRange: _priceRange,
        initialHasAc: _hasAc,
        initialHasWifi: _hasWifi,
        onApply: (newRange, newAc, newWifi) {
          setState(() {
            _priceRange = newRange;
            _hasAc = newAc;
            _hasWifi = newWifi;
          });
        },
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filteredDorms = MapView.mapDorms.where((dorm) {
      final name = dorm['name'].toString().toLowerCase();
      final location = dorm['location'].toString().toLowerCase();
      final rawPrice = dorm['price'].toString().split(' ').first.replaceAll(',', '');
      final price = int.tryParse(rawPrice) ?? 0;

      final matchesQuery = query.isEmpty || name.contains(query) || location.contains(query);
      final matchesPrice = price >= _priceRange.start.round() && price <= _priceRange.end.round();
      return matchesQuery && matchesPrice;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Enter dorm name or location...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Price Filter',
            onPressed: _openFilter,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View on Map',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapView())),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _openFilter,
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Price Rate: ฿${_formatNumber(_priceRange.start.round())} - ฿${_formatNumber(_priceRange.end.round())} / mo',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${filteredDorms.length} found',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredDorms.isEmpty
                ? const Center(
                    child: Text(
                      'No dormitories found in the selected price range',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDorms.length,
                    itemBuilder: (context, index) {
                      final dorm = filteredDorms[index];
                      final name = dorm['name'].toString();
                      final location = dorm['location'].toString();
                      final rawPrice = dorm['price'].toString().split(' ').first;
                      final imageUrl = dorm['image'].toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.apartment, color: AppColors.primary),
                              ),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$location · ฿$rawPrice / month'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DormDetailView(dormName: name)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}