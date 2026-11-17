import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../common/profile_view.dart';
import 'dorm_detail_view.dart';
import 'review_list_view.dart';

class MyReviewsView extends StatelessWidget {
  const MyReviewsView({super.key});

  String _getDisplayDormName(String dormName) {
    const map = {
      'หอพักสุขใจ 1': 'Hopak Sukjai 1',
      'หอพักสุขใจ 2': 'Hopak Sukjai 2',
      'หอพักสุขใจ 3': 'Hopak Sukjai 3',
      'หอพักสุขใจ 4': 'Hopak Sukjai 4',
    };
    return map[dormName] ?? dormName;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ReviewManager.updated,
      builder: (context, _, __) {
        final List myReviews = [];
        final currentUserName = ProfileView.userName.value.toLowerCase();

        ReviewManager.dormReviews.forEach((dormName, reviews) {
          for (int i = 0; i < reviews.length; i++) {
            final review = reviews[i];
            final reviewer = review['user'].toString().toLowerCase();

            // เช็กครอบคลุมทั้ง (You), (คุณ), You หรือชื่อโปรไฟล์ปัจจุบัน
            if (reviewer.contains('(you)') ||
                reviewer.contains('(คุณ)') ||
                reviewer == 'you' ||
                (currentUserName.isNotEmpty && reviewer.contains(currentUserName))) {
              myReviews.add({
                'dormName': dormName,
                'indexInDorm': i,
                'rating': review['rating'] ?? 5,
                'comment': review['comment'] ?? '',
              });
            }
          }
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('My Reviews (${myReviews.length})'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          body: myReviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text('No reviews from you yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Reviews you write on dormitory pages will appear here', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myReviews.length,
                  itemBuilder: (context, index) {
                    final item = myReviews[index];
                    final dormName = item['dormName'].toString();
                    final displayDormName = _getDisplayDormName(dormName);
                    final indexInDorm = item['indexInDorm'] as int;
                    final rating = item['rating'] as int;
                    final comment = item['comment'].toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0E7FF),
                          child: Icon(Icons.apartment, color: AppColors.primary),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayDormName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(comment),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          tooltip: 'Delete review',
                          onPressed: () {
                            ReviewManager.deleteReview(dormName, indexInDorm);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Review deleted'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DormDetailView(dormName: dormName)),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}