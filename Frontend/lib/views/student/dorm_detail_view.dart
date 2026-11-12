import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../models/dormitory.dart';
import '../../services/chat_service.dart';
import '../../services/dorm_service.dart';
import '../common/chat_view.dart';
import '../widgets/common.dart';
import 'review_form_view.dart';

/// Dorm detail: images, price, rooms, water/electricity rates, amenities, map, reviews, favorite, chat, call
class DormDetailView extends StatefulWidget {
  const DormDetailView({super.key, required this.dormId});
  final int dormId;

  @override
  State<DormDetailView> createState() => _DormDetailViewState();
}

class _DormDetailViewState extends State<DormDetailView> {
  late Future<(Dormitory, List<Review>, Review?)> _future;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Dormitory, List<Review>, Review?)> _load() async {
    final s = context.read<DormService>();
    final isStudent = context.read<AuthController>().user?.isStudent ?? false;
    final d = await s.detail(widget.dormId);
    final reviews = await s.reviews(widget.dormId);
    final mine = isStudent ? await s.myReview(widget.dormId) : null;
    return (d, reviews, mine);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _chat(Dormitory d) async {
    try {
      final c = await context.read<ChatService>().startWithOwner(d.id);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatView(conversationId: c.id)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return showSnack(context, 'หอพักนี้ไม่ได้ระบุเบอร์ติดต่อ', error: true);
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')));
    if (!ok && mounted) showSnack(context, 'โทรออกไม่ได้บนอุปกรณ์นี้', error: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.hasError) return Scaffold(appBar: AppBar(), body: ErrorRetry(message: snap.error.toString(), onRetry: _reload));
        final (d, reviews, mine) = snap.data!;
        return _detail(d, reviews, mine);
      },
    );
  }

  Widget _detail(Dormitory d, List<Review> reviews, Review? mine) {
    final user = context.watch<AuthController>().user;
    final isStudent = user?.isStudent ?? false;
    final fav = context.watch<FavoritesController>();
    final isFav = fav.isFavorite(d.id);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          actions: [
            if (isStudent)
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white),
                onPressed: () => fav.toggle(d.id),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: d.images.isEmpty
                ? NetImage(null, radius: 0)
                : Stack(fit: StackFit.expand, children: [
                    PageView.builder(
                      itemCount: d.images.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => NetImage(d.images[i].filePath, radius: 0),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_page + 1}/${d.images.length}', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Row(children: [
              Expanded(child: Text(d.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy))),
              if (!d.isVisibleToStudents) StatusChip(d.status),
            ]),
            RatingText(rating: d.avgRating, count: d.reviewCount),
            const SizedBox(height: 6),
            Text(formatPrice(d.pricePerMonth), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.teal)),
            const SizedBox(height: 6),
            InfoRow(Icons.place_outlined, '${d.zone} · ${d.address ?? 'ไม่ระบุที่อยู่'}'),
            InfoRow(Icons.directions_walk, 'ห่างจากมหาวิทยาลัย ${formatDistance(d.distanceMeters)}'),
            InfoRow(Icons.person_outline, 'เจ้าของ: ${d.ownerName ?? '-'}'),
            const SectionTitle('ค่าน้ำ / ค่าไฟ'),
            Card(
              child: Column(children: [
                ListTile(leading: const Icon(Icons.water_drop_outlined, color: AppColors.teal), title: const Text('ค่าน้ำ'),
                    trailing: Text(formatRate(d.waterRate, d.waterBillingType))),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.bolt_outlined, color: AppColors.orange), title: const Text('ค่าไฟ'),
                    trailing: Text(formatRate(d.electricityRate, d.electricityBillingType))),
              ]),
            ),
            if (d.amenities.isNotEmpty) ...[
              const SectionTitle('สิ่งอำนวยความสะดวก'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in d.amenities) Chip(avatar: const Icon(Icons.check_circle, size: 18, color: AppColors.teal), label: Text(a.name)),
              ]),
            ],
            if ((d.description ?? '').isNotEmpty) ...[const SectionTitle('รายละเอียด'), Text(d.description!)],
            const SectionTitle('ตำแหน่งที่ตั้ง'),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(d.latitude, d.longitude),
                    initialZoom: 15.5,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hophak.app'),
                    MarkerLayer(markers: [
                      Marker(point: LatLng(d.latitude, d.longitude), width: 40, height: 40,
                          child: const Icon(Icons.location_pin, color: AppColors.danger, size: 40)),
                    ]),
                  ],
                ),
              ),
            ),
            SectionTitle('รีวิว (${reviews.length})',
                trailing: isStudent
                    ? TextButton(
                        onPressed: () async {
                          final sent = await Navigator.push<bool>(
                              context, MaterialPageRoute(builder: (_) => ReviewFormView(dorm: d, existing: mine)));
                          if (sent == true) {
                            _reload();
                            if (mounted) showSnack(context, 'บันทึกรีวิวแล้ว');
                          }
                        },
                        child: Text(mine == null ? 'เขียนรีวิว' : 'แก้ไขรีวิวของฉัน'),
                      )
                    : null),
            if (reviews.isEmpty)
              const Text('ยังไม่มีรีวิว', style: TextStyle(color: AppColors.muted))
            else
              for (final r in reviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Text(r.userName ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Stars(r.rating)]),
                        if ((r.body ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.body!)),
                        Text(formatDate(r.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                  ),
                ),
            const SizedBox(height: 80),
          ]),
        ),
      ]),
      bottomNavigationBar: isStudent
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(onPressed: () => _call(d.contactPhone), icon: const Icon(Icons.call), label: const Text('โทร')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(onPressed: () => _chat(d), icon: const Icon(Icons.chat_bubble_outline), label: const Text('แชทกับเจ้าของ')),
                  ),
                ]),
              ),
            )
          : null,
    );
  }
}
