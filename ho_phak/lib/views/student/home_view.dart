import 'package:flutter/material.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/theme.dart';
import 'dorm_detail_view.dart';
import 'map_view.dart';
import 'search_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static final List _dormList = [
    {
      'name': 'Hopak Sukjai 1',
      'price': '฿3,500 / month',
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600',
    },
    {
      'name': 'Hopak Sukjai 2',
      'price': '฿4,200 / month',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
    },
    {
      'name': 'Hopak Sukjai 3',
      'price': '฿3,800 / month',
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600',
    },
    {
      'name': 'Hopak Sukjai 4',
      'price': '฿4,500 / month',
      'image': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello, Friend 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Find the right dormitory for you', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchView())),
                      decoration: InputDecoration(
                        hintText: 'Search dorm name, location...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapView())),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text('Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: FavoritesController.savedDormNames,
                  builder: (context, savedSet, _) {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _dormList.length,
                      itemBuilder: (context, index) => _buildDormCard(context, _dormList[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDormCard(BuildContext context, Map<String, String> dorm) {
    final dormName = dorm['name']!;
    final price = dorm['price']!;
    final imageUrl = dorm['image']!;
    final isLiked = FavoritesController.isFavorite(dormName);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DormDetailView(dormName: dormName)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Center(child: Icon(Icons.apartment, size: 40, color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        FavoritesController.toggleFavorite(dormName);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(!isLiked ? 'Saved "$dormName" to favorites' : 'Removed "$dormName" from favorites'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dormName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}