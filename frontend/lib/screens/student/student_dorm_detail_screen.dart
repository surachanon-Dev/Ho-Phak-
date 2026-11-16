import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../models/dormitory.dart';
import '../../models/review.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../../widgets/dorm_map.dart';
import '../chat_room_screen.dart';

/// รายละเอียดหอพักฝั่งนักศึกษา: ข้อมูลหอ, ค่าน้ำ-ไฟ, รีวิว, บันทึกรายการโปรด,
/// ติดต่อเจ้าของ (เปิดแชท) และดูเบอร์โทร
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
  Dormitory? _dorm;
  List<OwnerReview> _reviews = [];
  bool _favorite = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.services.publicDorms.detail(widget.dormitoryId),
        widget.services.publicDorms.reviews(widget.dormitoryId),
        widget.services.favorites.list(),
      ]);
      if (!mounted) return;
      final favs = results[2] as List;
      setState(() {
        _dorm = results[0] as Dormitory;
        _reviews = results[1] as List<OwnerReview>;
        _favorite = favs.any((f) => f.id == widget.dormitoryId);
      });
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _busy = true);
    try {
      if (_favorite) {
        await widget.services.favorites.remove(widget.dormitoryId);
      } else {
        await widget.services.favorites.add(widget.dormitoryId);
      }
      if (mounted) setState(() => _favorite = !_favorite);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// เปิดแชทกับเจ้าของ (ถ้ามีแชทเดิมจะใช้แชทเดิม)
  Future<void> _chat(Dormitory dorm) async {
    setState(() => _busy = true);
    try {
      final id = await widget.services.chats.open(dorm.id);
      if (!mounted) return;
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
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPhone(Dormitory dorm) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ติดต่อ ${dorm.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.phone),
                label: Text(dorm.contactPhone ?? 'ยังไม่ได้ระบุเบอร์'),
              ),
              const SizedBox(height: 8),
              const Text(
                'การโทรออกจากแอปยังไม่รองรับ กรุณากดเบอร์ด้านบนเพื่อจดไว้',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _writeReview() async {
    int rating = 5;
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('เขียนรีวิว'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: AppColors.warningText,
                      ),
                      onPressed: () => setInner(() => rating = i),
                    ),
                ],
              ),
              TextField(
                controller: body,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'เล่าประสบการณ์ของคุณ (ไม่บังคับ)',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'รีวิวจะแสดงหลังแอดมินตรวจสอบ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('ส่งรีวิว'),
            ),
          ],
        ),
      ),
    );
    final text = body.text.trim();
    body.dispose();
    if (ok != true) return;
    try {
      await widget.services.publicDorms.addReview(
        widget.dormitoryId,
        rating,
        text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งรีวิวแล้ว รอแอดมินตรวจสอบ')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dorm = _dorm;
    return Scaffold(
      appBar: AppBar(
        title: Text(dorm?.name ?? 'รายละเอียดหอพัก'),
        actions: [
          IconButton(
            tooltip: _favorite ? 'นำออกจากรายการโปรด' : 'บันทึกเป็นรายการโปรด',
            icon: Icon(
              _favorite ? Icons.favorite : Icons.favorite_border,
              color: _favorite ? AppColors.danger : null,
            ),
            onPressed: (dorm == null || _busy) ? null : _toggleFavorite,
          ),
        ],
      ),
      body: _loading && dorm == null
          ? const Center(child: CircularProgressIndicator())
          : dorm == null
          ? const Center(child: Text('ไม่พบหอพักนี้'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.apartment_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(dorm.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${dorm.zone}'
                  '${dorm.address != null ? ' · ${dorm.address}' : ''}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  '${dorm.pricePerMonth} บาท/เดือน',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dorm.availableRooms <= 0
                      ? 'เต็มแล้ว'
                      : 'ว่าง ${dorm.availableRooms} จาก ${dorm.totalRooms} ห้อง',
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'ค่าน้ำ-ค่าไฟ',
                  children: [
                    _Row(
                      label: 'ค่าน้ำ',
                      value: _rate(dorm.waterRate, dorm.waterBillingType),
                    ),
                    _Row(
                      label: 'ค่าไฟ',
                      value: _rate(
                        dorm.electricityRate,
                        dorm.electricityBillingType,
                      ),
                    ),
                  ],
                ),
                if (dorm.description != null)
                  _Section(
                    title: 'รายละเอียด',
                    children: [Text(dorm.description!)],
                  ),
                _Section(
                  title: 'ที่ตั้ง',
                  children: [
                    Text(
                      'พิกัด ${dorm.latitude}, ${dorm.longitude}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    const SizedBox(height: 8),
                    DormLocationMap(dorm: dorm),
                    if (dorm.address != null) ...[
                      const SizedBox(height: 6),
                      Text(dorm.address!),
                    ],
                  ],
                ),
                _Section(
                  title:
                      'รีวิว (${dorm.ratingAvg?.toStringAsFixed(1) ?? '-'} ดาว · ${_reviews.length} รีวิว)',
                  trailing: TextButton(
                    onPressed: _writeReview,
                    child: const Text('เขียนรีวิว'),
                  ),
                  children: [
                    if (_reviews.isEmpty)
                      const Text('ยังไม่มีรีวิว')
                    else
                      for (final r in _reviews)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '★' * r.rating,
                                style: const TextStyle(
                                  color: AppColors.warningText,
                                ),
                              ),
                              if (r.body != null && r.body!.isNotEmpty)
                                Text(r.body!),
                              Text(
                                r.createdAt,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPhone(dorm),
                        icon: const Icon(Icons.phone_outlined),
                        label: const Text('โทร'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _chat(dorm),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('แชท'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _rate(double? rate, String? type) {
    if (rate == null || type == null) return 'ไม่ได้ระบุ';
    return '$rate บาท (${BillingType.label(type)})';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
