import 'package:flutter/material.dart';

import '../../../../app/session.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../model/dormitory.dart' show zoneLabel;
import '../../../../model/favorite.dart';
import '../../../../widgets/ui/ui.dart';
import '../../../owner/widgets/owner_ui.dart' show DormCover;
import '../controller/favorites_controller.dart';
import '../../widgets/student_ui.dart';
import '../../dorm_detail/view/student_dorm_detail_screen.dart';

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
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
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
      appBar: AppBar(
        // อยู่ในแท็บของ StudentShell (มี actions) ไม่ต้องมีปุ่มย้อนกลับ
        automaticallyImplyLeading: widget.actions == null,
        title: const Text('Favorites'),
        actions: widget.actions,
      ),
      body: RefreshIndicator(
        onRefresh: _c.load,
        child: _c.showFullLoader
            ? const Center(child: CircularProgressIndicator())
            : _c.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.favorite_border_rounded,
                    tone: Tone.danger,
                    title: 'No favorite dorms yet',
                    message: 'Tap the heart on a dorm page to save it here.',
                    action: FilledButton.icon(
                      onPressed: widget.onExplore,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Find dorms'),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  StudentBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionTitle(
                          'Saved dorms',
                          subtitle:
                              '${_c.availableCount} of ${_c.items.length} available',
                        ),
                        const SizedBox(height: 12),
                        for (final f in _c.items) ...[
                          _FavoriteCard(
                            favorite: f,
                            onOpen: f.isAvailable ? () => _open(f.id) : null,
                            onRemove: () => _remove(f.id),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.onOpen,
    required this.onRemove,
  });

  final Favorite favorite;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final f = favorite;
    final available = f.isAvailable;
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Opacity(
            opacity: available ? 1 : 0.45,
            child: DormCover(url: f.coverUrl, width: 76, height: 76),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: available ? AppColors.text : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                if (available) ...[
                  PriceText(f.pricePerMonth, size: 14),
                  const SizedBox(height: 6),
                  ToneBadge(
                    label: zoneLabel(f.zone),
                    tone: Tone.primary,
                    icon: Icons.place_outlined,
                  ),
                ] else
                  const ToneBadge(
                    label: 'Unavailable',
                    tone: Tone.danger,
                    icon: Icons.block_rounded,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.favorite_rounded, color: AppColors.danger),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
