import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import 'dorm_detail_view.dart';

class MapView extends StatefulWidget {
  final String? initialDormName;
  const MapView({super.key, this.initialDormName});

  static final List mapDorms = [
    {
      'name': 'Hopak Sukjai 1',
      'price': '3,500 / month',
      'shortPrice': '3,500 THB/month',
      'zone': 'Front Gate · 0.3 km from MFU',
      'rating': '4.5',
      'lat': 20.0442,
      'lng': 99.8838,
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
    },
    {
      'name': 'Hopak Sukjai 2',
      'price': '4,200 / month',
      'shortPrice': '4,200 THB/month',
      'zone': 'Front Gate · 0.5 km from MFU',
      'rating': '4.7',
      'lat': 20.0418,
      'lng': 99.8845,
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    },
    {
      'name': 'Hopak Sukjai 3',
      'price': '3,800 / month',
      'shortPrice': '3,800 THB/month',
      'zone': 'Side Gate · 0.8 km from MFU',
      'rating': '4.6',
      'lat': 20.0492,
      'lng': 99.8862,
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    },
    {
      'name': 'Hopak Sukjai 4',
      'price': '4,500 / month',
      'shortPrice': '4,500 THB/month',
      'zone': 'Market Zone · 1.2 km from MFU',
      'rating': '4.8',
      'lat': 20.0392,
      'lng': 99.8835,
      'image': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800',
    },
  ];

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  // พิกัดศูนย์กลางมหาวิทยาลัยแม่ฟ้าหลวง (MFU Campus)
  static const LatLng _mfuCampus = LatLng(20.0455, 99.8935);

  // จุดกึ่งกลางมุมมองแผนที่ (ให้ MFU อยู่กลางจอและเห็นโซนหอพักรอบ ม. ครบทุกจุด)
  static const LatLng _initialCameraCenter = LatLng(20.0445, 99.8898);

  late Map<String, dynamic> _selectedDorm;
  bool _isNearMfu = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialDormName != null) {
      final match = MapView.mapDorms.where((d) => d['name'] == widget.initialDormName);
      _selectedDorm = match.isNotEmpty ? match.first : MapView.mapDorms.first;
    } else {
      _selectedDorm = MapView.mapDorms.first;
    }
  }

  void _selectDorm(Map<String, dynamic> dorm) {
    setState(() {
      _selectedDorm = dorm;
    });
    _mapController.move(
      LatLng(dorm['lat'] as double, dorm['lng'] as double),
      15.8,
    );
  }

  void _toggleLocationMode() {
    setState(() {
      _isNearMfu = !_isNearMfu;
    });
    if (_isNearMfu) {
      _mapController.move(_initialCameraCenter, 14.8);
    } else {
      _mapController.move(
        LatLng(_selectedDorm['lat'] as double, _selectedDorm['lng'] as double),
        16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLat = _selectedDorm['lat'] as double;
    final initialLng = _selectedDorm['lng'] as double;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text(
          'Map',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialDormName != null
                  ? LatLng(initialLat, initialLng)
                  : _initialCameraCenter,
              initialZoom: widget.initialDormName != null ? 15.8 : 14.8,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hophak.app',
              ),
              MarkerLayer(
                markers: [
                  // แลนด์มาร์กตรงกลาง: มหาวิทยาลัยแม่ฟ้าหลวง (MFU)
                  Marker(
                    point: _mfuCampus,
                    width: 150,
                    height: 66,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.school, color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Text(
                            'ม.แม่ฟ้าหลวง (MFU)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // หมุดหอพักแต่ละโซนรอบมหาวิทยาลัย
                  ...MapView.mapDorms.map((dorm) {
                    final isSelected = dorm['name'] == _selectedDorm['name'];
                    return Marker(
                      point: LatLng(dorm['lat'] as double, dorm['lng'] as double),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _selectDorm(dorm),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? const Color(0xFFD9480F)
                              : const Color(0xFF0066CC),
                          size: isSelected ? 40 : 32,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // แถบด้านบน: Near Mae Fah Luang University
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _toggleLocationMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isNearMfu ? Icons.school_outlined : Icons.my_location,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isNearMfu
                                ? 'Near Mae Fah Luang University'
                                : 'Near me (Current Location)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.swap_horiz, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _toggleLocationMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      _isNearMfu ? 'Tap to switch to Near me' : 'Tap to switch to MFU',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // การ์ดข้อมูลหอพักด้านล่าง
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DormDetailView(
                          dormName: _selectedDorm['name'].toString(),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _selectedDorm['image'].toString(),
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 58,
                              height: 58,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.apartment, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDorm['name'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDorm['zone'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDorm['shortPrice'].toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0066CC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DormDetailView(
                                dormName: _selectedDorm['name'].toString(),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Details',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066CC),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            final name = _selectedDorm['name'];
                            final lat = _selectedDorm['lat'];
                            final lng = _selectedDorm['lng'];
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening route to $name ($lat, $lng)...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.near_me_outlined, size: 16, color: Colors.white),
                          label: const Text(
                            'Directions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Opens Google Maps · route from Mae Fah Luang University',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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