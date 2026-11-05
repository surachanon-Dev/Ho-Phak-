import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../controller/owner_controller.dart';
import '../../controller/owner_session.dart';
import '../../models/dormitory.dart';
import '../theme/owner_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dormitory_map.dart';
import '../widgets/page_frame.dart';
import '../widgets/small_parts.dart';
import '../widgets/surface_card.dart';
import 'dormitory_form_screen.dart';

/// รายละเอียดหอ ปิดหน้านี้ด้วย true เมื่อมีการแก้ไขหรือลบ เพื่อให้หน้าหลักโหลดใหม่
class DormitoryDetailScreen extends StatefulWidget {
  const DormitoryDetailScreen({super.key, required this.dormitory});

  final Dormitory dormitory;

  @override
  State<DormitoryDetailScreen> createState() => _DormitoryDetailScreenState();
}

class _DormitoryDetailScreenState extends State<DormitoryDetailScreen> {
  Future<void> _edit() async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => DormitoryFormScreen(dormitory: widget.dormitory)));
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบ "${widget.dormitory.name}"?'),
        content: const Text('ข้อมูลของหอนี้จะถูกลบ และนักศึกษาจะค้นไม่เจออีก ย้อนกลับไม่ได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44), backgroundColor: OwnerColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบหอ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await OwnerController.deleteDormitory(widget.dormitory.id);
    OwnerSession.removeDetails(widget.dormitory.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = widget.dormitory;
    final details = OwnerSession.detailsOf(d.id);
    final rooms = details.availableRooms;
    final phone = OwnerSession.contact.phone;

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // รูปหอ (ยังไม่มีระบบอัปโหลดรูป จึงเป็นภาพแทน)
            Container(
              height: 240,
              width: double.infinity,
              color: OwnerColors.photo,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apartment, size: 48, color: OwnerColors.textMuted),
                  Text('[รูปหอพัก]', style: text.bodySmall?.copyWith(color: OwnerColors.textMuted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 220),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: OwnerColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: PageFrame(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(OwnerGap.page, 18, OwnerGap.page, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      d.name,
                                      style: text.headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w700, color: OwnerColors.navy),
                                    ),
                                  ),
                                  Text(
                                    rooms == null ? d.zone : '${d.zone} · ${rooms > 0 ? 'ว่าง $rooms ห้อง' : 'เต็ม'}',
                                    style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(padding: const EdgeInsets.only(top: 4), child: StatusPill(details.status)),
                          ],
                        ),
                        const SizedBox(height: OwnerGap.block),
                        SurfaceCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: withCommas(d.pricePerMonth),
                                  style: text.headlineSmall
                                      ?.copyWith(color: OwnerColors.primary, fontWeight: FontWeight.w700),
                                  children: [
                                    TextSpan(
                                      text: '  บาท/เดือน',
                                      style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: MiniStat(label: 'ค่าน้ำ', value: details.waterText)),
                                  const SizedBox(width: 6),
                                  Expanded(child: MiniStat(label: 'ค่าไฟ', value: details.electricText)),
                                  const SizedBox(width: 6),
                                  Expanded(child: MiniStat(label: 'มัดจำ', value: details.depositText)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: OwnerGap.block),
                        TitledCard(
                          title: 'สิ่งอำนวยความสะดวก',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (details.amenities.isEmpty)
                                Text('ยังไม่ได้ระบุ', style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted))
                              else
                                AmenityWrap(details.amenities),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 18, color: OwnerColors.textMuted),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ติดต่อ ${phoneWithDashes(phone)} (เบอร์ของคุณ)',
                                      style: text.bodyMedium?.copyWith(color: OwnerColors.textBody),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: OwnerGap.block),
                        TitledCard(
                          title: 'ที่อยู่และตำแหน่ง',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DormitoryMap(position: LatLng(d.latitude, d.longitude), height: 150),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.place_outlined, size: 20, color: OwnerColors.textMuted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          details.address.isEmpty ? 'ยังไม่ได้ระบุที่อยู่' : details.address,
                                          style: text.bodyMedium?.copyWith(height: 1.55),
                                        ),
                                        Text(
                                          'พิกัด ${d.latitude}, ${d.longitude}',
                                          style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: OwnerGap.block),
                        TitledCard(
                          title: 'รายละเอียด',
                          child: Text(
                            details.description.isEmpty ? 'ยังไม่ได้ระบุ' : details.description,
                            style: text.bodyMedium?.copyWith(
                              height: 1.6,
                              color: details.description.isEmpty ? OwnerColors.textMuted : OwnerColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: OwnerGap.block),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: OwnerColors.danger,
                                  side: const BorderSide(color: OwnerColors.danger),
                                ),
                                onPressed: _delete,
                                child: const Text('ลบหอ'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _edit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('แก้ไขข้อมูล'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: MediaQuery.paddingOf(context).top + 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'กลับ',
                  icon: const Icon(Icons.arrow_back, color: OwnerColors.navy),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
