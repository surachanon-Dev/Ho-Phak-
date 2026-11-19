import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../controller/location_picker_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/dorm_map.dart';

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
  late final LocationPickerController _c;

  @override
  void initState() {
    super.initState();
    _c = LocationPickerController(initial: widget.initial);
    _c.addListener(() {
      if (!mounted) return;
      setState(() {});
      final message = _c.message;
      if (message != null) _snack(message);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _map.dispose();
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));

  /// ขอตำแหน่งปัจจุบันของเครื่องแล้วเลื่อนแผนที่ไปที่นั่น
  Future<void> _useMyLocation() async {
    final ok = await _c.useMyLocation();
    if (ok && mounted) _map.move(_c.center, 17);
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
          icon: const Icon(Icons.arrow_back),
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
                    initialCenter: _c.center,
                    initialZoom: 16,
                    onPositionChanged: (camera, _) {
                      // อัปเดตข้อความระยะจาก MFU ตามจุดกึ่งกลางที่ลากไป
                      _c.setCenter(camera.center);
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
                      size: 52,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(color: Color(0x55000000), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                const IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xE60F172A),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          'Drag the map to move the pin',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 56,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Material(
                        color: AppColors.surface,
                        shape: const StadiumBorder(),
                        elevation: 3,
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
                      Material(
                        color: AppColors.surface,
                        shape: const StadiumBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: _c.locating ? null : _useMyLocation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _c.locating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Use my location',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pin set · ${_c.distanceFromMfuLabel} km from MFU',
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
