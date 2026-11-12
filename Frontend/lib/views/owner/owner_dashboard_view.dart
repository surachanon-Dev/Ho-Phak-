import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/owner_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import 'owner_shell.dart';

/// Owner dashboard: summary + count of my dorms per dormitories.status
class OwnerDashboardView extends StatelessWidget {
  const OwnerDashboardView({super.key, required this.onOpenDorms});
  final VoidCallback onOpenDorms;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    final c = context.watch<OwnerController>();
    final s = c.stats;

    return RefreshIndicator(
      onRefresh: () async => refreshAll(context),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('สวัสดี, ${user.displayName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 8),
        const NoticeCard(
          icon: Icons.info_outline,
          color: AppColors.navy,
          text: 'เพิ่มหอพักใหม่ต้องแนบรูปหอพักและเอกสารแสดงความเป็นเจ้าของ แล้วรอผู้ดูแลระบบอนุมัติ\n'
              'หอที่อนุมัติแล้วแก้ไขข้อมูลได้ทันที',
        ),
        if (c.error != null) NoticeCard(text: c.error!, color: AppColors.danger),
        if (s == null && c.loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else if (s != null) ...[
          const SectionTitle('ภาพรวม'),
          GridView.extent(
            maxCrossAxisExtent: 280,
            childAspectRatio: 1.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(label: 'หอพักทั้งหมด', value: '${s.total}', icon: Icons.apartment),
              StatCard(label: 'เผยแพร่แล้ว', value: '${s.count('published')}', icon: Icons.public, color: AppColors.orange),
              StatCard(label: 'รอผู้ดูแลระบบอนุมัติ', value: '${s.count('pending')}', icon: Icons.hourglass_top, color: AppColors.navy),
              StatCard(label: 'ข้อความยังไม่อ่าน', value: '${s.unreadMessages}', icon: Icons.chat_bubble_outline, color: AppColors.success),
            ],
          ),
          SectionTitle('สถานะหอพัก', trailing: TextButton(onPressed: onOpenDorms, child: const Text('ดูทั้งหมด'))),
          Card(
            child: Column(children: [
              for (final st in dormStatusLabels.keys)
                ListTile(
                  dense: true,
                  title: Align(alignment: Alignment.centerLeft, child: StatusChip(st)),
                  trailing: Text('${s.count(st)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
          if (s.count('rejected') > 0 || s.count('suspended') > 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: NoticeCard(
                color: AppColors.danger,
                text: 'มีหอพักที่ไม่อนุมัติหรือถูกระงับ – เปิดดูเหตุผลได้ในแท็บ "หอพัก"',
              ),
            ),
        ],
        const SizedBox(height: 80),
      ]),
    );
  }
}
