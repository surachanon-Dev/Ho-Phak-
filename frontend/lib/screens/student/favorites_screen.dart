import 'package:flutter/material.dart';

import '../../models/favorite.dart';
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
  List<Favorite> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await widget.services.favorites.list();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Favorite f) async {
    try {
      await widget.services.favorites.remove(f.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x.id == f.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('นำออกจากรายการโปรดแล้ว')));
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
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
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final f = _items[i];
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
                        onPressed: () => _remove(f),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
