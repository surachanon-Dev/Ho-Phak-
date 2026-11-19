/// วิธีระบุค่าน้ำ/ค่าไฟ (D-143, D-152)
enum UtilityMode { setPrice, included, notSpecified }

class DormUtilities {
  const DormUtilities({
    this.water = UtilityMode.notSpecified,
    this.electricity = UtilityMode.notSpecified,
  });

  final UtilityMode water;
  final UtilityMode electricity;

  Map<String, dynamic> toJson() => {
    'water': water.name,
    'electricity': electricity.name,
  };

  factory DormUtilities.fromJson(Map<String, dynamic> json) => DormUtilities(
    water: _mode(json['water']),
    electricity: _mode(json['electricity']),
  );

  static UtilityMode _mode(dynamic v) => UtilityMode.values.firstWhere(
    (m) => m.name == v,
    orElse: () => UtilityMode.notSpecified,
  );
}

/// โหมดที่ใช้แสดง/แก้: มีอัตราจาก server → setPrice เสมอ
/// ไม่มีอัตรา → ใช้ที่ผู้ใช้เลือกไว้ (Included / Not specified), ไม่มี = Not specified
UtilityMode utilityModeFor({required double? rate, UtilityMode? saved}) {
  if (rate != null) return UtilityMode.setPrice;
  if (saved == null || saved == UtilityMode.setPrice) {
    return UtilityMode.notSpecified;
  }
  return saved;
}
