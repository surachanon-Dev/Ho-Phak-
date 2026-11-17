import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/dormitory.dart';
import '../ui/app_theme.dart';

/// จุดกึ่งกลางมหาวิทยาลัยแม่ฟ้าหลวง ใช้เป็นค่าเริ่มต้นเมื่อไม่มีพิกัดหอ
const mfuCenter = LatLng(19.8801, 99.8323);

/// แผนที่ tile ของ OpenStreetMap (ต้องแสดงเครดิตตามข้อกำหนด)
class _OsmMap extends StatelessWidget {
  const _OsmMap({
    required this.center,
    required this.zoom,
    required this.markers,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hopak.frontend',
        ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

/// แผนที่แสดงตำแหน่งหอเดียว (หน้ารายละเอียด)
class DormLocationMap extends StatelessWidget {
  const DormLocationMap({super.key, required this.dorm, this.height = 200});

  final Dormitory dorm;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(dorm.latitude, dorm.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: _OsmMap(
          center: point,
          zoom: 16,
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: AppColors.danger,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// แผนที่แสดงหอพักทั้งหมดในผลค้นหา กดหมุดเพื่อเปิดรายละเอียด
class DormMarkersMap extends StatelessWidget {
  const DormMarkersMap({
    super.key,
    required this.dorms,
    required this.onSelect,
  });

  final List<Dormitory> dorms;
  final ValueChanged<Dormitory> onSelect;

  @override
  Widget build(BuildContext context) {
    return _OsmMap(
      center: mfuCenter,
      zoom: 14,
      markers: [
        for (final d in dorms)
          Marker(
            point: LatLng(d.latitude, d.longitude),
            width: 120,
            height: 56,
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${d.pricePerMonth} ฿',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
