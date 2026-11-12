import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import '../../services/admin_service.dart';
import '../widgets/common.dart';
import 'admin_common.dart';

/// Admin: full dorm data + actions allowed for its status
///  pending → check photos + ownership document → approve / reject(reason) · published, hidden → suspend(reason) · suspended → restore
class AdminDormDetailView extends StatefulWidget {
  const AdminDormDetailView({super.key, required this.dormId});
  final int dormId;

  @override
  State<AdminDormDetailView> createState() => _AdminDormDetailViewState();
}

class _AdminDormDetailViewState extends State<AdminDormDetailView> {
  late Future<Dormitory> _future = context.read<AdminService>().dorm(widget.dormId);
  void _reload() => setState(() => _future = context.read<AdminService>().dorm(widget.dormId));

  List<Widget> _actions(Dormitory d) {
    final s = context.read<AdminService>();
    Future<void> after(bool ok) async {
      if (ok) _reload();
    }

    return switch (d.status) {
      'pending' => [
          FilledButton.icon(
            onPressed: () async => after(await runAdmin(context, () => s.approveDorm(d.id), 'อนุมัติหอพักแล้ว')),
            icon: const Icon(Icons.check),
            label: const Text('อนุมัติ'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async => after(await runWithReason(context, 'ไม่อนุมัติหอพัก', (r) => s.rejectDorm(d.id, r), 'ไม่อนุมัติแล้ว')),
            icon: const Icon(Icons.close),
            label: const Text('ไม่อนุมัติ'),
          ),
        ],
      'published' || 'hidden' => [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async => after(await runWithReason(context, 'ระงับหอพัก', (r) => s.suspendDorm(d.id, r), 'ระงับหอพักแล้ว')),
            icon: const Icon(Icons.block),
            label: const Text('ระงับหอพัก'),
          ),
        ],
      'suspended' => [
          FilledButton.icon(
            onPressed: () async => after(await runAdmin(context, () => s.restoreDorm(d.id), 'คืนสถานะหอพักแล้ว')),
            icon: const Icon(Icons.restore),
            label: const Text('คืนสถานะ'),
          ),
        ],
      _ => [],
    };
  }

  Widget _document(String? url) {
    if (url == null || url.isEmpty) {
      return const NoticeCard(color: AppColors.danger, text: 'ไม่ได้แนบเอกสาร');
    }
    final isImage = !url.toLowerCase().endsWith('.pdf') && !url.startsWith('uploads/documents/');
    if (!isImage) return InfoRow(Icons.description_outlined, url.split('/').last);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: InteractiveViewer(child: NetImage(url, radius: 0, fit: BoxFit.contain))),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
          ]),
        ),
      ),
      child: NetImage(url, height: 180, width: double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดหอพัก')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
          final d = snap.data!;
          final actions = _actions(d);
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (d.images.isNotEmpty)
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: d.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => NetImage(d.images[i].filePath, width: 220, height: 160),
                ),
              )
            else
              const NoticeCard(text: 'หอพักนี้ยังไม่มีรูปภาพ'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(d.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy))),
              StatusChip(d.status),
            ]),
            if (d.status == 'rejected') Text('เหตุผลที่ไม่อนุมัติ: ${d.rejectionReason ?? '-'}', style: const TextStyle(color: AppColors.danger)),
            if (d.status == 'suspended') Text('เหตุผลที่ระงับ: ${d.statusReason ?? '-'}', style: const TextStyle(color: AppColors.danger)),
            if (d.statusChangedAt != null)
              Text('เปลี่ยนสถานะล่าสุด ${formatDateTime(d.statusChangedAt)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
            InfoRow(Icons.person_outline, 'เจ้าของ: ${d.ownerName ?? '-'} · ${d.ownerPhone ?? '-'}'),
            InfoRow(Icons.payments_outlined, formatPrice(d.pricePerMonth)),
            InfoRow(Icons.place_outlined, '${d.zone} · ${d.address ?? '-'}'),
            InfoRow(Icons.my_location, '${d.latitude.toStringAsFixed(5)}, ${d.longitude.toStringAsFixed(5)} (${formatDistance(d.distanceMeters)} จากมหาวิทยาลัย)'),
            InfoRow(Icons.water_drop_outlined, 'ค่าน้ำ ${formatRate(d.waterRate, d.waterBillingType)}'),
            InfoRow(Icons.bolt_outlined, 'ค่าไฟ ${formatRate(d.electricityRate, d.electricityBillingType)}'),
            InfoRow(Icons.call_outlined, d.contactPhone ?? '-'),
            if (d.amenities.isNotEmpty) InfoRow(Icons.check_circle_outline, d.amenities.map((a) => a.name).join(', ')),
            if ((d.description ?? '').isNotEmpty) ...[const SectionTitle('รายละเอียด'), Text(d.description!)],
            const SectionTitle('เอกสารแสดงความเป็นเจ้าของ'),
            _document(d.ownershipDocumentUrl),
            const SizedBox(height: 16),
            if (actions.isNotEmpty) Wrap(spacing: 12, runSpacing: 8, children: actions),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}
