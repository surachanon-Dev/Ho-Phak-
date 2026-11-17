import 'package:flutter/foundation.dart';

class ReviewController {
  static final ValueNotifier<int> updated = ValueNotifier<int>(0);

  static final Map<String, List > dormReviews = {
    'Hopak Sukjai 1': [
      {'user': 'Alice (Year 2)', 'rating': 5, 'comment': 'Clean room, very close to MFU front gate!'},
      {'user': 'Bob (Year 3)', 'rating': 4, 'comment': 'Quiet environment and fast Wi-Fi.'},
    ],
    'Hopak Sukjai 2': [
      {'user': 'Charlie (Year 1)', 'rating': 5, 'comment': 'Spacious room with good air conditioning.'},
    ],
  };

  static List getReviews(String dormName) {
    return dormReviews[dormName] ?? [];
  }

  static void addReview(String dormName, int rating, String comment) {
    dormReviews.putIfAbsent(dormName, () => []);
    dormReviews[dormName]!.insert(0, {
      'user': 'MFU Student (You)',
      'rating': rating,
      'comment': comment,
    });
    updated.value++;
  }

  static void deleteReview(String dormName, int index) {
    if (dormReviews[dormName] != null && index < dormReviews[dormName]!.length) {
      dormReviews[dormName]!.removeAt(index);
      updated.value++;
    }
  }
}