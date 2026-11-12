import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import '../../services/dorm_service.dart';
import '../widgets/common.dart';
import '../widgets/dorm_card.dart';
import 'dorm_detail_view.dart';

/// Published dorms on OpenStreetMap (dormitories.latitude / longitude)
class DormMapView extends StatefulWidget {
  const DormMapView({super.key});

  @override
  State<DormMapView> createState() => _DormMapViewState();
}

class _DormMapViewState extends State<DormMapView> {
  final _campus = LatLng(AppConfig.campusLat, AppConfig.campusLng);
  List<Dormitory> _items = [];
  Dormitory? _selected;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final items = await context.read<DormService>().search(const DormFilter(sort: 'distance'));
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  String _short(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);
    return Stack(children: [
      FlutterMap(
        options: MapOptions(initialCenter: _campus, initialZoom: 15, onTap: (_, __) => setState(() => _selected = null)),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hophak.app'),
          MarkerLayer(markers: [
            Marker(point: _campus, width: 44, height: 44, child: const Icon(Icons.school, color: AppColors.navy, size: 36)),
            for (final d in _items)
              Marker(
                point: LatLng(d.latitude, d.longitude),
                width: 64,
                height: 32,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = d),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selected?.id == d.id ? AppColors.orange : AppColors.teal,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Text(_short(d.pricePerMonth), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
          ]),
        ],
      ),
      Positioned(right: 12, top: 12, child: FloatingActionButton.small(heroTag: 'map_refresh', onPressed: _load, child: const Icon(Icons.refresh))),
      if (_selected != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: DormCard(
            dorm: _selected!,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DormDetailView(dormId: _selected!.id))),
          ),
        ),
    ]);
  }
}
