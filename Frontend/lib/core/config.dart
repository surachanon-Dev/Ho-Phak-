/// App configuration (MOCK MODE – data comes from lib/mock/mock_db.dart, no backend needed)
class AppConfig {
  static const bool mockMode = true;

  /// Reference point for "distance from university" (change to your campus gate).
  static const double campusLat = 19.8820;
  static const double campusLng = 99.8340;

  /// Values of dormitories.zone (enum in the database)
  static const zones = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];

  /// Values of water_billing_type / electricity_billing_type (enum in the database)
  static const billingTypes = ['per_unit', 'per_person_month', 'per_room_month'];
}
