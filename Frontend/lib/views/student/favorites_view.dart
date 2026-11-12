import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/favorites_controller.dart';
import '../../models/dormitory.dart';
import '../../services/dorm_service.dart';
import '../widgets/common.dart';
import '../widgets/dorm_card.dart';
import 'dorm_detail_view.dart';

/// favorites table (saved dorms of the logged-in student)
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key, this.standalone = false});
  final bool standalone; // opened from Profile → needs its own Scaffold

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  List<Dormitory> _items = [];
  bool _loading = true;
  Set<int>? _lastIds;

  Future<void> _load() async {
    final items = await context.read<DormService>().favorites();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesController>();
    // reload the list whenever the set of favorite ids changes (e.g. ♡ tapped on a detail page)
    if (_lastIds == null || !setEquals(_lastIds, fav.ids)) {
      _lastIds = Set.of(fav.ids);
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? const EmptyState(icon: Icons.favorite_border, message: 'ยังไม่มีรายการโปรด\nกด ♡ ที่หอพักเพื่อบันทึกไว้')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = _items[i];
                    return DormCard(
                      dorm: d,
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.redAccent),
                        onPressed: () => fav.toggle(d.id),
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DormDetailView(dormId: d.id))),
                    );
                  },
                ),
              );
    return widget.standalone ? Scaffold(appBar: AppBar(title: const Text('รายการโปรด')), body: body) : body;
  }
}
