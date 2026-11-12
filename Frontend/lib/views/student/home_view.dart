import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/config.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import '../../services/dorm_service.dart';
import '../widgets/common.dart';
import '../widgets/dorm_card.dart';
import 'dorm_detail_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.onOpenSearch});
  final void Function({String? zone, String? sort}) onOpenSearch;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Future<(List<Dormitory>, List<Dormitory>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<Dormitory>, List<Dormitory>)> _load() async {
    final s = context.read<DormService>();
    final top = await s.search(const DormFilter(sort: 'rating'));
    final near = await s.search(const DormFilter(sort: 'distance'));
    return (top.take(5).toList(), near.take(5).toList());
  }

  void _open(Dormitory d) => Navigator.push(context, MaterialPageRoute(builder: (_) => DormDetailView(dormId: d.id)));

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().user?.displayName ?? '';
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('สวัสดี, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const Text('กำลังมองหาหอพักที่ใช่อยู่ใช่ไหม?', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => widget.onOpenSearch(),
            child: const IgnorePointer(
              child: TextField(decoration: InputDecoration(hintText: 'ค้นหาชื่อหอพัก ที่อยู่ โซน...', prefixIcon: Icon(Icons.search))),
            ),
          ),
          const SectionTitle('โซน'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final z in AppConfig.zones)
              ActionChip(
                avatar: const Icon(Icons.place, size: 18, color: AppColors.teal),
                label: Text(z),
                onPressed: () => widget.onOpenSearch(zone: z),
              ),
          ]),
          FutureBuilder(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: () => setState(() => _future = _load()));
              final (top, near) = snap.data!;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionTitle('หอพักแนะนำ (คะแนนสูง)',
                    trailing: TextButton(onPressed: () => widget.onOpenSearch(sort: 'rating'), child: const Text('ดูทั้งหมด'))),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: top.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: 220,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _open(top[i]),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            NetImage(top[i].coverImage, height: 120, width: 220, radius: 0),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(top[i].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                                Text(formatPrice(top[i].pricePerMonth), style: const TextStyle(color: AppColors.teal, fontSize: 13)),
                                RatingText(rating: top[i].avgRating, count: top[i].reviewCount),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                SectionTitle('ใกล้มหาวิทยาลัย',
                    trailing: TextButton(onPressed: () => widget.onOpenSearch(sort: 'distance'), child: const Text('ดูทั้งหมด'))),
                for (final d in near) Padding(padding: const EdgeInsets.only(bottom: 10), child: DormCard(dorm: d, onTap: () => _open(d))),
              ]);
            },
          ),
        ],
      ),
    );
  }
}
