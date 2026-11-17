import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DormMiniMap extends StatelessWidget {
  final double lat;
  final double lng;
  final String dormName;
  final double height;
  final VoidCallback? onTap;

  const DormMiniMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.dormName,
    this.height = 120,
    this.onTap,
  });

  // พิกัดมหาวิทยาลัยแม่ฟ้าหลวง (MFU)
  static const LatLng _mfuLocation = LatLng(20.0458, 99.8944);

  @override
  Widget build(BuildContext context) {
    final dormLocation = LatLng(lat, lng);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: dormLocation,
            initialZoom: 15.2,
            // ล็อกการเลื่อน/ซูมในกรอบเล็ก เพื่อไม่ให้ตีกับการเลื่อนหน้าจอหลัก
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hophak.app',
            ),
            MarkerLayer(
              markers: [
                // หมุดมหาวิทยาลัยแม่ฟ้าหลวง (MFU)
                Marker(
                  point: _mfuLocation,
                  width: 75,
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MFU',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // หมุดตำแหน่งหอพัก
                Marker(
                  point: dormLocation,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFD9480F),
                    size: 32,
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