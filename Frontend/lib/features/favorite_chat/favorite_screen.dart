import 'package:flutter/material.dart';
import '../../../../ho_phak/lib/core/theme/app_colors.dart';
import '../dorm_detail/dorm_detail_screen.dart';

class FavoriteManager {
  static final ValueNotifier<List> savedDorms = ValueNotifier([]);

  static bool isFavorite(String dormName) {
    return savedDorms.value.any((d) => d['name'] == dormName);
  }

  static void toggleFavorite(String dormName, String price) {
    final currentList = List.from(savedDorms.value);
    final index = currentList.indexWhere((d) => d['name'] == dormName);

    if (index >= 0) {
      currentList.removeAt(index);
    } else {
      currentList.add({'name': dormName, 'price': price});
    }
    savedDorms.value = currentList;
  }
}

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

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
      body: ValueListenableBuilder<List>(
        valueListenable: FavoriteManager.savedDorms,
        builder: (context, savedDorms, _) {
          if (savedDorms.isEmpty) {
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
            itemCount: savedDorms.length,
            itemBuilder: (context, index) {
              final dorm = savedDorms[index];
              final name = dorm['name'].toString();
              final price = dorm['price'].toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.apartment, color: AppColors.primary, size: 32),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(price),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    onPressed: () => FavoriteManager.toggleFavorite(name, price),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DormDetailScreen(dormName: name)),
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