import '../../../shared/models/dormitory.dart';

/// สรุปตัวเลขของหอทั้งหมดที่เจ้าของมี (ใช้บนหน้า My Dorms)
class DormitorySummary {
  DormitorySummary._(this.totalAvailable, this.published, this.attention);

  factory DormitorySummary.of(List<Dormitory> items) {
    // นับหอที่ต้องให้เจ้าของดู: รอตรวจ, ไม่ผ่าน, ถูกระงับ
    final attention = <String, int>{};
    for (final d in items) {
      final s = d.status;
      if (s == DormStatus.pending ||
          s == DormStatus.rejected ||
          s == DormStatus.suspended) {
        attention[s] = (attention[s] ?? 0) + 1;
      }
    }
    return DormitorySummary._(
      items.fold<int>(0, (s, d) => s + d.availableRooms),
      items.where((d) => d.status == DormStatus.published).length,
      attention,
    );
  }

  final int totalAvailable;
  final int published;

  /// สถานะ → จำนวนหอ (เฉพาะ pending / rejected / suspended)
  final Map<String, int> attention;

  int get attentionTotal => attention.values.fold<int>(0, (s, n) => s + n);
}
