import 'package:flutter/material.dart';

import '../../controller/student/favorites_controller.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import 'student_dorm_detail_screen.dart';

/// รายการโปรด: หอที่ถูกซ่อนหรือระงับจะแสดงเป็น "ไม่พร้อมให้บริการ" และกดเข้าดูไม่ได้
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.services,
    required this.myUserId,
    this.onExplore,
  });

  final AppServices services;
  final int myUserId;

  /// กดปุ่ม "ไปค้นหาหอพัก" (ให้หน้าหลักสลับไปแท็บค้นหา)
  final VoidCallback? onExplore;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
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
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final f = _c.items[i];
                  final available = f.isAvailable;
                  return Card(
                    child: ListTile(
                      onTap: available
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentDormDetailScreen(
                                  services: widget.services,
                                  dormitoryId: f.id,
                                  myUserId: widget.myUserId,
                                ),
                              ),
                            )
                          : null,
                      title: Text(
                        f.name,
                        style: TextStyle(
                          color: available ? null : AppColors.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        available
                            ? '${f.zone} · ${f.pricePerMonth} บาท/เดือน'
                            : 'ไม่พร้อมให้บริการ',
                        style: TextStyle(
                          color: available
                              ? AppColors.textMuted
                              : AppColors.danger,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'นำออก',
                        icon: const Icon(
                          Icons.favorite,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _remove(f.id),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
