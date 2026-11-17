import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/student/favorites/favorites_controller.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/core/utils/format.dart';
import 'package:hopak_frontend/features/student/widgets/student_widgets.dart';
import 'package:hopak_frontend/features/student/dorm_detail/student_dorm_detail_screen.dart';

/// รายการโปรด: หอที่ถูกซ่อนหรือระงับจะแสดงเป็น "ไม่พร้อมให้บริการ" และกดเข้าดูไม่ได้
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.services,
    required this.myUserId,
    this.onExplore,
    this.actions,
  });

  final AppServices services;
  final int myUserId;

  /// กดปุ่ม "ไปค้นหาหอพัก" (ให้หน้าหลักสลับไปแท็บค้นหา)
  final VoidCallback? onExplore;

  /// ปุ่มบน app bar (แชท / แจ้งเตือน)
  final List<Widget>? actions;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesController _c;

  @override
  void initState() {
    super.initState();
    _c = FavoritesController(widget.services.favorites);
    _c.addListener(_onChanged);
    _c.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    super.dispose();
  }

  Future<void> _remove(int dormitoryId) async {
    final ok = await _c.remove(dormitoryId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('นำออกจากรายการโปรดแล้ว')));
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  void _open(int dormitoryId) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentDormDetailScreen(
        services: widget.services,
        dormitoryId: dormitoryId,
        myUserId: widget.myUserId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด'), actions: widget.actions),
      body: RefreshIndicator(
        onRefresh: _c.load,
        child: _c.showFullLoader
            ? const Center(child: CircularProgressIndicator())
            : _c.items.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  const Icon(
                    Icons.favorite_border,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Center(child: Text('ยังไม่มีหอพักในรายการโปรด')),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'กดรูปหัวใจในหน้ารายละเอียดหอพักเพื่อบันทึกไว้',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: widget.onExplore,
                      child: const Text('ไปค้นหาหอพัก'),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _c.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final f = _c.items[i];
                  final available = f.isAvailable;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: available ? () => _open(f.id) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: available ? 1 : 0.4,
                              child: const NetImage(null, width: 72, height: 72),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: available
                                          ? null
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (available) ...[
                                    Text(
                                      formatPrice(f.pricePerMonth),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      f.zone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ] else
                                    const Text(
                                      'ไม่พร้อมให้บริการ',
                                      style: TextStyle(color: AppColors.danger),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'นำออก',
                              icon: const Icon(
                                Icons.favorite,
                                color: AppColors.danger,
                              ),
                              onPressed: () => _remove(f.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
