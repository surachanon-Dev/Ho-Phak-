import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/app_theme.dart';
import '../../ui/format.dart';
import '../../widgets/dorm_map.dart';

/// ปักหมุดตำแหน่งหอพัก: ลากแผนที่ให้หมุดตรงตำแหน่ง แล้วกดยืนยัน
/// คืนค่าเป็น LatLng ของจุดกึ่งกลางหมุด (pop(LatLng))
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _map = MapController();
  late LatLng _center = widget.initial ?? mfuCenter;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _confirm() {
    // อ่านจุดกึ่งกลางจริงของแผนที่ ณ ตอนกดยืนยัน
    Navigator.of(context).pop(_map.camera.center);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set dorm location'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 16,
                    onPositionChanged: (camera, _) {
                      // อัปเดตข้อความระยะจาก MFU ตามจุดกึ่งกลางที่ลากไป
                      setState(() => _center = camera.center);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hopak.frontend',
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                // หมุดคงที่กลางจอ ผู้ใช้ลากแผนที่ใต้หมุด + คำอธิบายใต้หมุด
                const IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.location_pin,
                      size: 48,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(top: 56),
                    child: Text(
                      'Drag the map to move the pin',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        backgroundColor: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                ),
                // ชิปมหาวิทยาลัย: แตะเพื่อเลื่อนแผนที่ไปที่ MFU
                Positioned(
                  left: 16,
                  bottom: 72,
                  child: Material(
                    color: AppColors.surface,
                    shape: const StadiumBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => _map.move(mfuCenter, 16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Mae Fah Luang University',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pin set · ${kmFromMfu(_center.latitude, _center.longitude)} km from MFU',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _confirm,
                    child: const Text('Confirm location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
