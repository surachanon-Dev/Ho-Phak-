import 'package:flutter/material.dart';
import '../../../../ho_phak/lib/core/theme/app_colors.dart';
import '../dorm_detail/dorm_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String? initialDormName;
  const MapScreen({super.key, this.initialDormName});

  static final List mapDorms = [
    {
      'name': 'Hopak Sukjai 1',
      'location': 'Front Gate · 0.3 km from MFU',
      'price': '3,500 THB/month',
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600',
      'top': 250.0,
      'left': 110.0,
      'miniTop': 35.0,
      'miniLeft': 115.0,
    },
    {
      'name': 'Hopak Sukjai 2',
      'location': 'Front Gate · 0.5 km from MFU',
      'price': '4,200 THB/month',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
      'top': 155.0,
      'left': 75.0,
      'miniTop': 18.0,
      'miniLeft': 75.0,
    },
    {
      'name': 'Hopak Sukjai 3',
      'location': 'Side Gate · 0.8 km from MFU',
      'price': '3,800 THB/month',
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600',
      'top': 140.0,
      'left': 230.0,
      'miniTop': 22.0,
      'miniLeft': 195.0,
    },
    {
      'name': 'Hopak Sukjai 4',
      'location': 'Market Zone · 1.2 km from MFU',
      'price': '4,500 THB/month',
      'image': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=600',
      'top': 285.0,
      'left': 245.0,
      'miniTop': 62.0,
      'miniLeft': 220.0,
    },
  ];

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late int _selectedIndex;
  bool _isNearMe = false;

  @override
  void initState() {
    super.initState();
    final idx = widget.initialDormName != null
        ? MapScreen.mapDorms.indexWhere((d) => d['name'] == widget.initialDormName)
        : 0;
    _selectedIndex = idx >= 0 ? idx : 0;
  }

  void _handleLocationSwitch() {
    if (_isNearMe) {
      setState(() => _isNearMe = false);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.near_me_outlined, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use your location?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Allow Ho-Phak to use your location to show dorms near you. You can switch back to Mae Fah Luang University anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Not now', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _isNearMe = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Allow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDorm = MapScreen.mapDorms[_selectedIndex];
    final name = selectedDorm['name'].toString();
    final location = selectedDorm['location'].toString();
    final price = selectedDorm['price'].toString();
    final imageUrl = selectedDorm['image'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      appBar: AppBar(
        title: const Text('Map', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(painter: _FigmaMapPainter()),
          ),

          Positioned(
            top: 190,
            left: 145,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isNearMe ? AppColors.primary : const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(
                    _isNearMe ? Icons.my_location : Icons.school,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                  ),
                  child: Text(
                    _isNearMe ? 'You' : 'MFU',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          ...List.generate(MapScreen.mapDorms.length, (index) {
            final dorm = MapScreen.mapDorms[index];
            final isSelected = index == _selectedIndex;

            return Positioned(
              top: dorm['top'] as double,
              left: dorm['left'] as double,
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.location_on,
                    color: isSelected ? const Color(0xFFD9480F) : AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
            );
          }),

          Positioned(
            top: 16,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _handleLocationSwitch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isNearMe ? Icons.my_location : Icons.school_outlined,
                          size: 18,
                          color: _isNearMe ? AppColors.primary : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isNearMe ? 'Near me (Current Location)' : 'Near Mae Fah Luang University',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.swap_horiz, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isNearMe ? 'Tap to switch to MFU' : 'Tap to switch to Near me',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DormDetailScreen(dormName: name)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
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
                              child: const Center(child: Text('[Photo]', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(location, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DormDetailScreen(dormName: name)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening Google Maps directions to "$name"...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.near_me_outlined, size: 16, color: Colors.white),
                          label: const Text('Directions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isNearMe
                        ? 'Opens Google Maps · route from Your Location'
                        : 'Opens Google Maps · route from Mae Fah Luang University',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

class _FigmaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()..color = const Color(0xFFD8E8D3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(30, 120, 110, 75), const Radius.circular(12)),
      greenPaint,
    );

    final waterPaint = Paint()..color = const Color(0xFFCDE1F5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.55, size.height * 0.42, 130, 90), const Radius.circular(36)),
      waterPaint,
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 95), Offset(size.width, 95), roadPaint);
    canvas.drawLine(Offset(0, 240), Offset(size.width, 200), roadPaint);
    canvas.drawLine(Offset(size.width * 0.52, 0), Offset(size.width * 0.52, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}