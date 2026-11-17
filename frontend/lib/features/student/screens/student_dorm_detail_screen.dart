import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/session.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/models/chat.dart';
import '../../../shared/models/dormitory.dart';
import '../../../shared/widgets/dorm_map.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../owner/widgets/owner_ui.dart' show DormCover;
import '../controllers/dorm_detail_controller.dart';
import '../widgets/student_ui.dart';
import 'review_form_screen.dart';

/// รายละเอียดหอพักฝั่งนักศึกษา: รูปหอ, ราคา, ระยะทาง, ค่าน้ำ-ไฟ,
/// สิ่งอำนวยความสะดวก, แผนที่, รีวิว, รายการโปรด, โทร และแชทกับเจ้าของ
class StudentDormDetailScreen extends StatefulWidget {
  const StudentDormDetailScreen({
    super.key,
    required this.services,
    required this.dormitoryId,
    this.myUserId = 0,
  });

  final AppServices services;
  final int dormitoryId;
  final int myUserId;

  @override
  State<StudentDormDetailScreen> createState() =>
      _StudentDormDetailScreenState();
}

class _StudentDormDetailScreenState extends State<StudentDormDetailScreen> {
  late final DormDetailController _c;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _c = DormDetailController(
      dormitoryId: widget.dormitoryId,
      myUserId: widget.myUserId,
      dorms: widget.services.publicDorms,
      favorites: widget.services.favorites,
      chats: widget.services.chats,
    );
    _c.addListener(_onChanged);
    _c.load().then((ok) {
      if (!ok && mounted && _c.error != null) {
        showApiError(context, widget.services, _c.error!);
      }
    });
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

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _toggleFavorite() async {
    final ok = await _c.toggleFavorite();
    if (!mounted) return;
    if (ok) {
      _snack(
        _c.isFavorite ? 'บันทึกเป็นรายการโปรดแล้ว' : 'นำออกจากรายการโปรดแล้ว',
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  /// เปิดแชทกับเจ้าของ (ถ้ามีแชทเดิมจะใช้แชทเดิม)
  Future<void> _chat(Dormitory dorm) async {
    final id = await _c.openChat();
    if (!mounted) return;
    if (id == null) {
      if (_c.error != null) showApiError(context, widget.services, _c.error!);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          services: widget.services,
          conversation: Conversation(
            id: id,
            tenantId: widget.myUserId,
            dormitoryName: dorm.name,
            dormitoryStatus: dorm.status,
            unreadCount: 0,
          ),
          myUserId: widget.myUserId,
          asStudent: true,
        ),
      ),
    );
  }

  /// โทรหาเจ้าของ ถ้าอุปกรณ์โทรไม่ได้ (เช่น เปิดบนคอมพิวเตอร์) จะแสดงเบอร์ให้จดแทน
  Future<void> _call(Dormitory dorm) async {
    final phone = dorm.contactPhone?.trim() ?? '';
    if (phone.isEmpty) return _snack('หอพักนี้ไม่ได้ระบุเบอร์ติดต่อ');
    final uri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^0-9+]'), ''),
    );
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) _snack('โทรออกไม่ได้บนอุปกรณ์นี้ เบอร์ติดต่อ: $phone');
  }

  Future<void> _writeReview(Dormitory dorm) async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          dormName: dorm.name,
          onSubmit: (rating, body) async {
            final ok = await _c.submitReview(rating: rating, body: body);
            if (!ok && mounted && _c.error != null) {
              showApiError(context, widget.services, _c.error!);
            }
            return ok;
          },
        ),
      ),
    );
    if (sent == true && mounted) _snack('ส่งรีวิวแล้ว รอแอดมินตรวจสอบ');
  }

  @override
  Widget build(BuildContext context) {
    final dorm = _c.dorm;
    if (dorm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดหอพัก')),
        body: _c.loading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.apartment_outlined,
                title: 'ไม่พบหอพักนี้',
                action: OutlinedButton(
                  onPressed: _c.load,
                  child: const Text('ลองอีกครั้ง'),
                ),
              ),
      );
    }
    final full = dorm.availableRooms <= 0;
    final distance = formatDistance(
      metersFromMfu(dorm.latitude, dorm.longitude),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.surface,
            title: Text(dorm.name),
            actions: [
              IconButton(
                tooltip: _c.isFavorite
                    ? 'นำออกจากรายการโปรด'
                    : 'บันทึกเป็นรายการโปรด',
                style: IconButton.styleFrom(backgroundColor: AppColors.surface),
                icon: Icon(
                  _c.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _c.isFavorite ? AppColors.danger : AppColors.text,
                ),
                onPressed: _c.busy ? null : _toggleFavorite,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
                child: _Gallery(
                  images: dorm.images,
                  page: _page,
                  onPage: (i) => setState(() => _page = i),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverToBoxAdapter(
              child: StudentBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dorm.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RatingText(
                            rating: dorm.ratingAvg,
                            count: dorm.reviewCount,
                          ),
                          const SizedBox(height: 10),
                          PriceText(dorm.pricePerMonth, size: 22),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ToneBadge(
                                label: dorm.zone,
                                tone: Tone.primary,
                                icon: Icons.place_outlined,
                              ),
                              ToneBadge(
                                label: 'ห่างมหาวิทยาลัย $distance',
                                tone: Tone.info,
                                icon: Icons.directions_walk_rounded,
                              ),
                              ToneBadge(
                                label: full
                                    ? 'เต็มแล้ว'
                                    : 'ว่าง ${dorm.availableRooms} จาก ${dorm.totalRooms} ห้อง',
                                tone: full ? Tone.danger : Tone.success,
                                icon: Icons.meeting_room_outlined,
                              ),
                            ],
                          ),
                          if ((dorm.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              dorm.description!,
                              style: const TextStyle(
                                color: AppColors.textBody,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle(
                      'ค่าใช้จ่ายและที่อยู่',
                      icon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          InfoRow(
                            icon: Icons.water_drop_outlined,
                            label: 'ค่าน้ำ',
                            value: _rate(dorm.waterRate, dorm.waterBillingType),
                          ),
                          InfoRow(
                            icon: Icons.bolt_outlined,
                            label: 'ค่าไฟ',
                            value: _rate(
                              dorm.electricityRate,
                              dorm.electricityBillingType,
                            ),
                          ),
                          InfoRow(
                            icon: Icons.home_outlined,
                            label: 'ที่อยู่',
                            value: dorm.address ?? 'ไม่ระบุ',
                          ),
                        ],
                      ),
                    ),
                    if (dorm.amenityNames.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const SectionTitle(
                        'สิ่งอำนวยความสะดวก',
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in dorm.amenityNames)
                            ToneBadge(
                              label: a,
                              tone: Tone.success,
                              icon: Icons.check_rounded,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    const SectionTitle(
                      'ตำแหน่งที่ตั้ง',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: 10),
                    DormLocationMap(dorm: dorm, height: 190),
                    const SizedBox(height: 18),
                    SectionTitle(
                      'รีวิว (${_c.reviews.length})',
                      icon: Icons.reviews_outlined,
                      trailing: TextButton.icon(
                        onPressed: () => _writeReview(dorm),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('เขียนรีวิว'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_c.reviews.isEmpty)
                      const AppCard(
                        child: EmptyState(
                          compact: true,
                          icon: Icons.rate_review_outlined,
                          title: 'ยังไม่มีรีวิว',
                          message: 'เป็นคนแรกที่รีวิวหอพักนี้',
                        ),
                      )
                    else
                      for (final r in _c.reviews) ...[
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stars(r.rating),
                                  const Spacer(),
                                  Text(
                                    formatDate(r.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              if ((r.body ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  r.body!,
                                  style: const TextStyle(
                                    color: AppColors.textBody,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: StudentBody(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(dorm),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('โทร'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _c.busy ? null : () => _chat(dorm),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('แชทกับเจ้าของ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _rate(double? rate, String? type) {
    if (rate == null || type == null) return 'ไม่ได้ระบุ';
    return '$rate บาท (${BillingType.label(type)})';
  }
}

/// รูปหอแบบเลื่อนดูได้ พร้อมตัวนับ "1/3" ถ้าไม่มีรูปจะแสดงกรอบไล่สี
class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.page,
    required this.onPage,
  });

  final List<DormImage> images;
  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const DormCover(url: null, radius: 0);
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onPage,
          itemBuilder: (_, i) => DormCover(url: images[i].fullUrl, radius: 0),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: ToneBadge(
            label: '${page + 1}/${images.length}',
            tone: Tone.neutral,
            icon: Icons.photo_library_outlined,
          ),
        ),
      ],
    );
  }
}
