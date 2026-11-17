import 'package:flutter/foundation.dart';

@immutable
class AdminAmenity {
  const AdminAmenity({
    required this.id,
    required this.name,
    this.usedByCount = 0,
    this.addedLabel = 'Today',
  });

  final String id;
  final String name;
  final int usedByCount;
  final String addedLabel;
}

/// Edits the local catalogue displayed by the Amenities page.
class AdminAmenitiesController extends ChangeNotifier {
  AdminAmenitiesController(Iterable<AdminAmenity> items)
    : _items = List.of(items);

  final List<AdminAmenity> _items;
  int _lastLocalId = 0;

  List<AdminAmenity> get items => List.unmodifiable(_items);

  AdminAmenity add(String name) {
    final trimmed = _validatedName(name);
    String id;
    do {
      id = 'local-${++_lastLocalId}';
    } while (_items.any((item) => item.id == id));

    final amenity = AdminAmenity(id: id, name: trimmed);
    _items.add(amenity);
    notifyListeners();
    return amenity;
  }

  AdminAmenity rename(String id, String name) {
    final index = _indexOf(id);
    if (index < 0) throw StateError('Amenity no longer exists');

    final original = _items[index];
    final renamed = AdminAmenity(
      id: original.id,
      name: _validatedName(name, exceptId: id),
      usedByCount: original.usedByCount,
      addedLabel: original.addedLabel,
    );
    _items[index] = renamed;
    notifyListeners();
    return renamed;
  }

  bool delete(String id) {
    final index = _indexOf(id);
    if (index < 0) return false;

    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  String _validatedName(String name, {String? exceptId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Please enter an amenity name.');
    }

    final normalized = trimmed.toLowerCase();
    final duplicate = _items.any(
      (item) =>
          item.id != exceptId && item.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const FormatException('This amenity name already exists.');
    }
    return trimmed;
  }
}
