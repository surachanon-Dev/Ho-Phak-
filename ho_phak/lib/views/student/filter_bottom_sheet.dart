import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'map_view.dart';

class FilterBottomSheet extends StatefulWidget {
  final RangeValues initialPriceRange;
  final bool initialHasAc;
  final bool initialHasWifi;
  final Function(RangeValues priceRange, bool hasAc, bool hasWifi)? onApply;

  const FilterBottomSheet({
    super.key,
    this.initialPriceRange = const RangeValues(2500, 6000),
    this.initialHasAc = true,
    this.initialHasWifi = true,
    this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late bool _hasAc;
  late bool _hasWifi;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialPriceRange;
    _hasAc = widget.initialHasAc;
    _hasWifi = widget.initialHasWifi;
  }

  int _getMatchingDormCount() {
    return MapView.mapDorms.where((dorm) {
      final rawPrice = dorm['price'].toString().split(' ').first.replaceAll(',', '');
      final price = int.tryParse(rawPrice) ?? 0;
      return price >= _priceRange.start.round() && price <= _priceRange.end.round();
    }).length;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final startPrice = _priceRange.start.round();
    final endPrice = _priceRange.end.round();
    final matchCount = _getMatchingDormCount();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Filter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(2500, 6000);
                    _hasAc = true;
                    _hasWifi = true;
                  });
                },
                child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range: ฿${_formatNumber(startPrice)} - ฿${_formatNumber(endPrice)} / month',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$matchCount found',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 1500,
            max: 15000,
            divisions: 27,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              '฿${_formatNumber(startPrice)}',
              '฿${_formatNumber(endPrice)}',
            ),
            onChanged: (val) => setState(() => _priceRange = val),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('฿1,500', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('฿15,000', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickRangeChip('Budget (≤ ฿3,800)', const RangeValues(1500, 3800)),
              _buildQuickRangeChip('Mid-range (฿3,800 - ฿4,500)', const RangeValues(3800, 4500)),
              _buildQuickRangeChip('All', const RangeValues(1500, 15000)),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Air Conditioner (AC)'),
            value: _hasAc,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _hasAc = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Free Wi-Fi'),
            value: _hasWifi,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _hasWifi = val),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                if (widget.onApply != null) {
                  widget.onApply!(_priceRange, _hasAc, _hasWifi);
                }
                Navigator.pop(context);
              },
              child: Text(
                'Show Results ($matchCount items)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRangeChip(String label, RangeValues targetRange) {
    final isSelected = _priceRange.start.round() == targetRange.start.round() &&
        _priceRange.end.round() == targetRange.end.round();

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      onSelected: (_) => setState(() => _priceRange = targetRange),
    );
  }
}