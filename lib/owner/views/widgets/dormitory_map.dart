import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/owner_theme.dart';

// ตำแหน่งตั้งต้นของแผนที่เมื่อยังไม่มีพิกัด: บริเวณมหาวิทยาลัยแม่ฟ้าหลวง (ค่าประมาณ)
const LatLng defaultMapCenter = LatLng(20.0446, 99.8938);

// แผนที่ OpenStreetMap แสดงหมุดของหอ ถ้าส่ง onPick มา จะแตะบนแผนที่เพื่อเลือกตำแหน่งได้
class DormitoryMap extends StatefulWidget {
  const DormitoryMap({super.key, this.position, this.height = 160, this.onPick});

  final LatLng? position;
  final double height;
  final ValueChanged<LatLng>? onPick;

  @override
  State<DormitoryMap> createState() => _DormitoryMapState();
}

class _DormitoryMapState extends State<DormitoryMap> {
  final _controller = MapController();

  @override
  void didUpdateWidget(DormitoryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.position;
    if (next != null && next != oldWidget.position) {
      _controller.move(next, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    return Semantics(
      label: 'แผนที่ตำแหน่งหอพัก',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OwnerRadius.tile + 2),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: position ?? defaultMapCenter,
              initialZoom: 15,
              interactionOptions: InteractionOptions(
                flags: widget.onPick == null ? InteractiveFlag.none : InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: widget.onPick == null ? null : (_, point) => widget.onPick!(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ho_phak_1',
              ),
              if (position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, size: 40, color: OwnerColors.danger),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
