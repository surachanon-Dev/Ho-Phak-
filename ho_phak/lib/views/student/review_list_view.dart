import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ReviewManager {
  static final ValueNotifier<int> updated = ValueNotifier<int>(0);

  // Store reviews per dormitory name (starts empty)
  static final Map<String, List > dormReviews = {};

  static List getReviews(String dormName) {
    if (!dormReviews.containsKey(dormName)) {
      dormReviews[dormName] = [];
    }
    return dormReviews[dormName]!;
  }

  static void addReview(String dormName, int rating, String comment) {
    final list = getReviews(dormName);
    list.insert(0, {
      'user': 'MFU Student (You)',
      'rating': rating,
      'comment': comment,
    });
    updated.value++;
  }

  static void deleteReview(String dormName, int index) {
    final list = getReviews(dormName);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      updated.value++;
    }
  }
}

class ReviewListView extends StatefulWidget {
  final String dormName;
  const ReviewListView({super.key, this.dormName = 'หอพักสุขใจ 1'});

  @override
  State<ReviewListView> createState() => _ReviewListViewState();
}

class _ReviewListViewState extends State<ReviewListView> {
  void _confirmDeleteReview(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this review?'),
        content: const Text('Are you sure you want to delete your review for this dormitory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ReviewManager.deleteReview(widget.dormName, index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review deleted'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewSheet() {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write a review for ${widget.dormName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setSheetState(() => selectedRating = starIndex),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Share your living experience here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;

                      ReviewManager.addReview(widget.dormName, selectedRating, text);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Review submitted!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ReviewManager.updated,
      builder: (context, _, __) {
        final reviews = ReviewManager.getReviews(widget.dormName);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('All Reviews (${reviews.length})'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          body: reviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text('No reviews for this dormitory yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Tap "Write a Review" below to be the first to share your thoughts', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final user = review['user'].toString();
                    final rating = (review['rating'] as int?) ?? 5;
                    final comment = review['comment'].toString();
                    final isMe = user.contains('(You)');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMe ? AppColors.primary : const Color(0xFFE0E7FF),
                          child: Icon(Icons.person, color: isMe ? Colors.white : AppColors.primary),
                        ),
                        title: Row(
                          children: [
                            Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
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
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(comment),
                        ),
                        trailing: isMe
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                tooltip: 'Delete review',
                                onPressed: () => _confirmDeleteReview(index),
                              )
                            : null,
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showWriteReviewSheet,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.rate_review, color: Colors.white),
            label: const Text('Write a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}