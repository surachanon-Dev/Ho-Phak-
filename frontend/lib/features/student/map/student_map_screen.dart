import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/features/student/dorm_detail/student_dorm_detail_screen.dart';
import 'package:hopak_frontend/features/student/home/student_home_controller.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/shared/widgets/dorm_card.dart';
import 'package:hopak_frontend/shared/widgets/dorm_map.dart' show mfuCenter;

/// แผนที่หอพักที่เผยแพร่แล้ว (ตาม map_view ของ Frontend-Big)
/// หมุดแสดงราคา กดหมุดเพื่อดูการ์ดหอด้านล่าง กดการ์ดเพื่อเปิดรายละเอียด
class StudentMapScreen extends StatefulWidget {
  const StudentMapScreen({
    super.key,
    required this.services,
    this.myUserId = 0,
    this.actions,
  });

  final AppServices services;
  final int myUserId;
  final List<Widget>? actions;

  @override
  State<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends State<StudentMapScreen> {
  // ใช้ controller เดียวกับหน้าแรก เพราะต้องการหอที่เผยแพร่ทั้งหมดเหมือนกัน
  late final StudentHomeController _c;
  Dormitory? _selected;

  @override
  void initState() {
    super.initState();
    _c = StudentHomeController(widget.services.publicDorms);
    _c.addListener(_onChanged);
    _c.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    super.dispose();
  }

  /// 3500 → "3.5k" ให้หมุดไม่กว้างเกินไป
  static String _short(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  void _open(Dormitory d) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentDormDetailScreen(
        services: widget.services,
        dormitoryId: d.id,
        myUserId: widget.myUserId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่'), actions: widget.actions),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: mfuCenter,
              initialZoom: 15,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hopak.frontend',
              ),
              MarkerLayer(
                markers: [
                  const Marker(
                    point: mfuCenter,
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.school,
                      color: Color(0xFF183B56),
                      size: 36,
                    ),
                  ),
                  for (final d in _c.items)
                    Marker(
                      point: LatLng(d.latitude, d.longitude),
                      width: 64,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = d),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected?.id == d.id
                                ? const Color(0xFFF4A261)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            _short(d.pricePerMonth),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (_c.loading) const LinearProgressIndicator(),
          Positioned(
            right: 12,
            top: 12,
            child: FloatingActionButton.small(
              heroTag: 'student_map_refresh',
              tooltip: 'โหลดใหม่',
              onPressed: _c.loading ? null : _c.refresh,
              child: const Icon(Icons.refresh),
            ),
          ),
          if (_c.error != null)
            Positioned(
              left: 12,
              right: 64,
              top: 12,
              child: Material(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('โหลดหอพักไม่ได้ กดปุ่มด้านขวาเพื่อลองใหม่'),
                ),
              ),
            ),
          if (selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: DormCard(dorm: selected, onTap: () => _open(selected)),
            ),
        ],
      ),
    );
  }
}
