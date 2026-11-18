import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hopak_frontend/features/student/dorm_detail/dorm_detail_controller.dart';
import 'package:hopak_frontend/features/student/review/review_form_screen.dart';
import 'package:hopak_frontend/features/student/widgets/student_widgets.dart';
import 'package:hopak_frontend/shared/models/chat.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/core/utils/format.dart';
import 'package:hopak_frontend/shared/widgets/dorm_map.dart';
import 'package:hopak_frontend/features/chat/chat_room/chat_room_screen.dart';

/// รายละเอียดหอพักฝั่งนักศึกษา (หน้าตาตาม Frontend-Big): รูปหอ, ราคา, ระยะทาง,
/// ค่าน้ำ-ไฟ, สิ่งอำนวยความสะดวก, แผนที่, รีวิว, รายการโปรด, โทร และแชทกับเจ้าของ
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
      _snack(_c.isFavorite ? 'บันทึกเป็นรายการโปรดแล้ว' : 'นำออกจากรายการโปรดแล้ว');
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
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
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
                message: 'ไม่พบหอพักนี้',
                action: OutlinedButton(
                  onPressed: _c.load,
                  child: const Text('ลองอีกครั้ง'),
                ),
              ),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            title: Text(dorm.name),
            actions: [
              IconButton(
                tooltip: _c.isFavorite
                    ? 'นำออกจากรายการโปรด'
                    : 'บันทึกเป็นรายการโปรด',
                icon: Icon(
                  _c.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _c.isFavorite ? AppColors.danger : null,
                ),
                onPressed: _c.busy ? null : _toggleFavorite,
              ),
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
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Text(
                  dorm.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                RatingText(rating: dorm.ratingAvg, count: dorm.reviewCount),
                const SizedBox(height: 6),
                Text(
                  formatPrice(dorm.pricePerMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                InfoRow(
                  Icons.place_outlined,
                  '${dorm.zone} · ${dorm.address ?? 'ไม่ระบุที่อยู่'}',
                ),
                InfoRow(
                  Icons.directions_walk,
                  'ห่างจากมหาวิทยาลัย ${formatDistance(metersFromMfu(dorm.latitude, dorm.longitude))}',
                ),
                InfoRow(
                  Icons.meeting_room_outlined,
                  dorm.availableRooms <= 0
                      ? 'เต็มแล้ว'
                      : 'ว่าง ${dorm.availableRooms} จาก ${dorm.totalRooms} ห้อง',
                ),
                if ((dorm.description ?? '').isNotEmpty) ...[
                  const SectionTitle('รายละเอียด'),
                  Text(dorm.description!),
                ],
                const SectionTitle('ค่าน้ำ / ค่าไฟ'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.water_drop_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text('ค่าน้ำ'),
                        trailing: Text(
                          _rate(dorm.waterRate, dorm.waterBillingType),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.bolt_outlined,
                          color: Color(0xFFF4A261),
                        ),
                        title: const Text('ค่าไฟ'),
                        trailing: Text(
                          _rate(
                            dorm.electricityRate,
                            dorm.electricityBillingType,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (dorm.amenityNames.isNotEmpty) ...[
                  const SectionTitle('สิ่งอำนวยความสะดวก'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in dorm.amenityNames)
                        Chip(
                          avatar: const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(a),
                        ),
                    ],
                  ),
                ],
                const SectionTitle('ตำแหน่งที่ตั้ง'),
                DormLocationMap(dorm: dorm, height: 180),
                SectionTitle(
                  'รีวิว (${_c.reviews.length})',
                  trailing: TextButton(
                    onPressed: () => _writeReview(dorm),
                    child: const Text('เขียนรีวิว'),
                  ),
                ),
                if (_c.reviews.isEmpty)
                  const Text(
                    'ยังไม่มีรีวิว',
                    style: TextStyle(color: AppColors.textMuted),
                  )
                else
                  for (final r in _c.reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                              if ((r.body ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(r.body!),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _call(dorm),
                  icon: const Icon(Icons.call),
                  label: const Text('โทร'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _c.busy ? null : () => _chat(dorm),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('แชทกับเจ้าของ'),
                ),
              ),
            ],
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

/// รูปหอแบบเลื่อนดูได้ พร้อมตัวนับ "1/3" ถ้าไม่มีรูปจะแสดงกรอบไอคอน
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
    if (images.isEmpty) return const NetImage(null, radius: 0);
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onPage,
          itemBuilder: (_, i) => NetImage(images[i].fullUrl, radius: 0),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${page + 1}/${images.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
