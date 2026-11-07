import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../models/review.dart';
import '../services/app_services.dart';
import '../ui/app_theme.dart';
import '../ui/error_handling.dart';
import '../ui/status_style.dart';
import 'dormitory_form_screen.dart';

/// รายละเอียดหอพักฝั่งเจ้าของ: สถานะ, สวิตช์แสดงให้นักศึกษาเห็น,
/// ห้อง/ค่าน้ำ-ค่าไฟ, รีวิว (อ่านอย่างเดียว) และแก้ไข
/// pop(true) เมื่อมีการเปลี่ยนแปลง เพื่อให้หน้ารายการโหลดใหม่
class DormitoryDetailScreen extends StatefulWidget {
  const DormitoryDetailScreen({
    super.key,
    required this.services,
    required this.dormitoryId,
  });

  final AppServices services;
  final int dormitoryId;

  @override
  State<DormitoryDetailScreen> createState() => _DormitoryDetailScreenState();
}

class _DormitoryDetailScreenState extends State<DormitoryDetailScreen> {
  Dormitory? _dorm;
  List<OwnerReview> _reviews = [];
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.services.dormitories.get(widget.dormitoryId),
        widget.services.dormitories.reviews(widget.dormitoryId),
      ]);
      if (!mounted) return;
      setState(() {
        _dorm = results[0] as Dormitory;
        _reviews = results[1] as List<OwnerReview>;
      });
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVisibility() async {
    setState(() => _busy = true);
    try {
      await widget.services.dormitories.toggleVisibility(widget.dormitoryId);
      _changed = true;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _dorm?.status == DormStatus.published
                  ? 'เปิดให้นักศึกษาเห็นแล้ว'
                  : 'ซ่อนหอพักจากนักศึกษาแล้ว',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final dorm = _dorm;
    if (dorm == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DormitoryFormScreen(services: widget.services, existing: dorm),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  void _contactAdmin() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ติดต่อแอดมิน'),
        content: const Text('ช่องทางติดต่อแอดมินยังไม่ได้กำหนด (รอการยืนยัน)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  /// ข้อความอธิบายสถานะ
  String _statusMessage(String status) => switch (status) {
    DormStatus.published => 'นักศึกษาเห็นและติดต่อหอพักนี้ได้',
    DormStatus.pending =>
      'รอแอดมินตรวจสอบ นักศึกษาจะเห็นหลังได้รับการอนุมัติ มักใช้เวลา 1–2 วัน',
    DormStatus.changesPending =>
      'การแก้ไขรอแอดมินตรวจสอบ นักศึกษายังเห็นข้อมูลเวอร์ชันเดิม',
    DormStatus.rejected => 'แอดมินไม่อนุมัติ แก้ไขแล้วส่งให้ตรวจสอบอีกครั้งได้',
    DormStatus.hidden => 'นักศึกษาค้นหาหอพักนี้ไม่เจอ ผู้ที่เคยบันทึกหรือแชทไว้จะเห็นว่า "ไม่พร้อมให้บริการ"',
    DormStatus.suspended =>
      'แอดมินระงับหอพักนี้ เปลี่ยนการแสดงผลไม่ได้ ติดต่อแอดมินเพื่อแก้ไข',
    _ => '',
  };

  String _toggleNote(Dormitory d) => switch (d.status) {
    DormStatus.published => 'ปิดเพื่อซ่อนหอพักจากการค้นหา',
    DormStatus.hidden => 'เปิดเพื่อให้หอพักนี้กลับมาแสดงอีกครั้ง',
    DormStatus.suspended => 'ล็อกระหว่างถูกระงับ',
    DormStatus.pending ||
    DormStatus.rejected => 'จะเปิดให้ใช้ได้หลังแอดมินอนุมัติ',
    _ => 'ยังไม่สามารถเปลี่ยนได้ในสถานะนี้',
  };

  double? get _avgRating => _reviews.isEmpty
      ? null
      : _reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length;

  @override
  Widget build(BuildContext context) {
    final dorm = _dorm;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(dorm?.name ?? 'รายละเอียดหอพัก'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: _loading && dorm == null
            ? const Center(child: CircularProgressIndicator())
            : dorm == null
            ? const Center(child: Text('ไม่พบหอพักนี้'))
            : AbsorbPointer(
                absorbing: _busy,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Cover(dorm: dorm),
                    const SizedBox(height: 16),

                    // ---- สถานะ ----
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DormStatus.label(dorm.status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                StatusChip(displayStatus: dorm.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_statusMessage(dorm.status)),
                            if (dorm.statusReason != null &&
                                dorm.statusReason!.isNotEmpty &&
                                (dorm.status == DormStatus.rejected ||
                                    dorm.status ==
                                        DormStatus.changesPending)) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'เหตุผลจากแอดมิน: ${dorm.statusReason}',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (dorm.status == DormStatus.rejected ||
                                dorm.status == DormStatus.changesPending)
                              FilledButton(
                                onPressed: _edit,
                                child: const Text('แก้ไขและส่งใหม่'),
                              ),
                            if (dorm.status == DormStatus.suspended)
                              FilledButton(
                                onPressed: _contactAdmin,
                                child: const Text('ติดต่อแอดมิน'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- สวิตช์แสดงให้นักศึกษาเห็น ----
                    Card(
                      child: SwitchListTile(
                        title: const Text('แสดงให้นักศึกษาเห็น'),
                        subtitle: Text(_toggleNote(dorm)),
                        value: dorm.status == DormStatus.published,
                        onChanged: dorm.canToggleVisibility
                            ? (_) => _toggleVisibility()
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _Section(
                      title: 'ห้องพัก',
                      children: [
                        _InfoRow(
                          label: 'ห้องทั้งหมด',
                          value: '${dorm.totalRooms} ห้อง',
                        ),
                        _InfoRow(
                          label: 'ห้องว่างตอนนี้',
                          value: '${dorm.availableRooms} ห้อง',
                        ),
                      ],
                    ),

                    _Section(
                      title: 'ข้อมูลหอพัก',
                      children: [
                        _InfoRow(label: 'โซน', value: dorm.zone),
                        _InfoRow(
                          label: 'ราคา/เดือน',
                          value: '${dorm.pricePerMonth} บาท',
                        ),
                        _InfoRow(
                          label: 'ค่าน้ำ',
                          value: _billingText(
                            dorm.waterRate,
                            dorm.waterBillingType,
                          ),
                        ),
                        _InfoRow(
                          label: 'ค่าไฟ',
                          value: _billingText(
                            dorm.electricityRate,
                            dorm.electricityBillingType,
                          ),
                        ),
                        if (dorm.address != null)
                          _InfoRow(label: 'ที่อยู่', value: dorm.address!),
                        if (dorm.contactPhone != null)
                          _InfoRow(
                            label: 'เบอร์ติดต่อ',
                            value: dorm.contactPhone!,
                          ),
                        if (dorm.description != null)
                          _InfoRow(
                            label: 'รายละเอียด',
                            value: dorm.description!,
                          ),
                        _InfoRow(
                          label: 'พิกัด',
                          value: '${dorm.latitude}, ${dorm.longitude}',
                        ),
                      ],
                    ),

                    _Section(
                      title: _avgRating == null
                          ? 'รีวิว'
                          : 'รีวิว (${_avgRating!.toStringAsFixed(1)} ดาว · ${_reviews.length} รีวิว)',
                      children: [
                        if (_reviews.isEmpty)
                          const Text('ยังไม่มีรีวิวที่เผยแพร่')
                        else
                          ..._reviews.map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${'★' * r.rating}  ${r.createdAt}'),
                                  if (r.body != null && r.body!.isNotEmpty)
                                    Text(r.body!),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        const Text(
                          'อ่านอย่างเดียว เจ้าของตอบกลับรีวิวไม่ได้',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    if (dorm.canEdit)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'ยังไม่รองรับการลบหอพักใน API นี้',
                                      ),
                                    ),
                                  ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _edit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit dorm'),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'หอพักถูกระงับ แก้ไขไม่ได้',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _billingText(double? rate, String? type) {
    if (rate == null || type == null) return 'ไม่ได้ระบุ';
    final unit = type == BillingType.perUnit ? 'บาท/หน่วย' : 'บาท';
    return '$rate $unit (${BillingType.label(type)})';
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.dorm});

  final Dormitory dorm;

  @override
  Widget build(BuildContext context) {
    final cover = dorm.images.isEmpty ? null : dorm.images.first.fullUrl;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: cover == null
            ? const ColoredBox(
                color: Colors.black12,
                child: Center(child: Text('ยังไม่มีรูปหอพัก')),
              )
            : Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black12,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
