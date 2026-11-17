import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets/dorm_mini_map.dart';
import '../common/chat_view.dart';
import 'map_view.dart';
import 'review_list_view.dart';

class DormDetailView extends StatefulWidget {
  final String dormName;
  const DormDetailView({super.key, required this.dormName});

  @override
  State<DormDetailView> createState() => _DormDetailViewState();
}

class _DormDetailViewState extends State<DormDetailView> {
  // Dormitory details mapped by dormName
  Map<String, dynamic> _getDormInfo() {
    final dormData = {
      'Hopak Sukjai 1': {
        'displayName': 'Hopak Sukjai 1',
        'price': '฿3,500/mo',
        'rawPrice': '฿3,500 / month',
        'water': '18 THB/unit',
        'electricity': '7 THB/unit',
        'location': 'Front Gate · 0.3 km from MFU',
        'owner': 'Bank',
        'phone': '081-234-5678',
        'rating': '4.5',
        'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
        'lat': 20.0435,
        'lng': 99.8920,
      },
      'Hopak Sukjai 2': {
        'displayName': 'Hopak Sukjai 2',
        'price': '฿4,200/mo',
        'rawPrice': '฿4,200 / month',
        'water': '18 THB/unit',
        'electricity': '7 THB/unit',
        'location': 'Front Gate · 0.5 km from MFU',
        'owner': 'Somchai',
        'phone': '089-876-5432',
        'rating': '4.7',
        'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
        'lat': 20.0422,
        'lng': 99.8935,
      },
      'Hopak Sukjai 3': {
        'displayName': 'Hopak Sukjai 3',
        'price': '฿3,800/mo',
        'rawPrice': '฿3,800 / month',
        'water': '15 THB/unit',
        'electricity': '7 THB/unit',
        'location': 'Side Gate · 0.8 km from MFU',
        'owner': 'Malee',
        'phone': '086-555-1234',
        'rating': '4.6',
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
        'lat': 20.0475,
        'lng': 99.8905,
      },
      'Hopak Sukjai 4': {
        'displayName': 'Hopak Sukjai 4',
        'price': '฿4,500/mo',
        'rawPrice': '฿4,500 / month',
        'water': '18 THB/unit',
        'electricity': '8 THB/unit',
        'location': 'Market Zone · 1.2 km from MFU',
        'owner': 'Nattapong',
        'phone': '082-333-9999',
        'rating': '4.8',
        'image': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800',
        'lat': 20.0405,
        'lng': 99.8895,
      },
    };

    return dormData[widget.dormName] ??
        {
          'displayName': widget.dormName,
          'price': '฿3,500/mo',
          'rawPrice': '฿3,500 / month',
          'water': '18 THB/unit',
          'electricity': '7 THB/unit',
          'location': 'Front Gate · 0.3 km from MFU',
          'owner': 'Bank',
          'phone': '081-234-5678',
          'rating': '4.5',
          'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
          'lat': 20.0435,
          'lng': 99.8920,
        };
  }

  void _showContactSheet(String displayName, String ownerName, String phoneNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              // Title
              Text(
                'Contact $displayName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // Owner & Phone
              Text(
                'Owner: $ownerName · $phoneNumber',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Blue Call Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling $phoneNumber...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.phone_outlined, color: Colors.white, size: 22),
                      Expanded(
                        child: Text(
                          'Call $phoneNumber',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Gray Copy Number Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: phoneNumber));
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied $phoneNumber to clipboard'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text(
                    'Copy number',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Outlined Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoGallery(String displayName, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(displayName, style: const TextStyle(fontSize: 16)),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _getDormInfo();
    final displayName = info['displayName'] as String;
    final price = info['price'] as String;
    final water = info['water'] as String;
    final electricity = info['electricity'] as String;
    final location = info['location'] as String;
    final owner = info['owner'] as String;
    final phone = info['phone'] as String;
    final rating = info['rating'] as String;
    final imageUrl = info['image'] as String;
    final lat = info['lat'] as double;
    final lng = info['lng'] as double;

    final amenities = ['Air Conditioner', 'Free Wi-Fi', 'Parking', 'CCTV'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesController.savedDormNames,
            builder: (context, _, __) {
              final isLiked = FavoritesController.isFavorite(widget.dormName);
              return IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.error : AppColors.textPrimary,
                ),
                onPressed: () {
                  FavoritesController.toggleFavorite(widget.dormName);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(!isLiked
                          ? 'Saved "$displayName" to favorites'
                          : 'Removed "$displayName" from favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            GestureDetector(
              onTap: () => _showPhotoGallery(displayName, imageUrl),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.apartment, size: 50, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  Container(
                    height: 190,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.25),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
                      SizedBox(height: 6),
                      Text(
                        'Tap to view all photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dorm Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066CC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Water $water · Electricity $electricity',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mini Map Preview Card (OpenStreetMap จริง)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          child: DormMiniMap(
                            lat: lat,
                            lng: lng,
                            dormName: displayName,
                            height: 120,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapView(initialDormName: widget.dormName),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFD9480F)),
                                  const SizedBox(width: 6),
                                  Text(
                                    location,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapView(initialDormName: widget.dormName),
                                  ),
                                ),
                                child: const Text(
                                  'View on map ›',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0066CC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Amenities Section
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: amenities.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Resident Reviews Section
                  ValueListenableBuilder<int>(
                    valueListenable: ReviewManager.updated,
                    builder: (context, _, __) {
                      final reviews = ReviewManager.getReviews(widget.dormName);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Resident Reviews (${reviews.length} reviews · $rating ★)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewListView(dormName: widget.dormName),
                              ),
                            ),
                            child: const Text(
                              'See all ›',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066CC),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Chat Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatView(dormName: displayName),
                  ),
                ),
                icon: const Icon(Icons.chat_outlined, size: 18, color: AppColors.textPrimary),
                label: const Text(
                  'Chat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Call Button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => _showContactSheet(displayName, owner, phone),
                icon: const Icon(Icons.phone_outlined, size: 18, color: Colors.white),
                label: const Text(
                  'Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}