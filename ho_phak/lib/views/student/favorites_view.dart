import 'package:flutter/material.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/theme.dart';
import 'dorm_detail_view.dart';
import 'map_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  String _getDormPrice(String dormName) {
    final match = MapView.mapDorms.where((d) => d['name'] == dormName);
    if (match.isNotEmpty) {
      final raw = match.first['price'].toString().split(' ').first;
      return '฿$raw / month';
    }
    return '฿3,500 / month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Saved Dormitories'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: FavoritesController.savedDormNames,
        builder: (context, savedNames, _) {
          final dormList = savedNames.toList();

          if (dormList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No favorites yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Tap the heart icon on any dormitory to save it here', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dormList.length,
            itemBuilder: (context, index) {
              final name = dormList[index];
              final price = _getDormPrice(name);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.apartment, color: AppColors.primary, size: 32),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(price),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    onPressed: () => FavoritesController.toggleFavorite(name),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DormDetailView(dormName: name)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}