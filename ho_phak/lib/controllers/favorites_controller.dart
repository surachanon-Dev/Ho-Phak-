import 'package:flutter/foundation.dart';

class FavoritesController {
  static final ValueNotifier<Set<String>> savedDormNames = ValueNotifier<Set<String>>({});

  static bool isFavorite(String dormName) => savedDormNames.value.contains(dormName);

  static void toggleFavorite(String dormName) {
    final updated = Set<String>.from(savedDormNames.value);
    if (updated.contains(dormName)) {
      updated.remove(dormName);
    } else {
      updated.add(dormName);
    }
    savedDormNames.value = updated;
  }
}