import 'package:flutter/material.dart';

import '../theme/owner_theme.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface_card.dart';

/// สถานะการยืนยันตัวตนของ owner (ยังไม่มีรายการเอกสารและประวัติการตรวจ)
class VerifyDocsScreen extends StatelessWidget {
  const VerifyDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('เอกสารยืนยันตัวตน')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 8, OwnerGap.page, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SurfaceCard(
                  color: OwnerColors.primaryTint,
                  borderColor: OwnerColors.primaryTint,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.verified_user_outlined, color: OwnerColors.primaryText),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ยืนยันตัวตนแล้ว',
                              style: text.titleMedium
                                  ?.copyWith(color: OwnerColors.primaryText, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'บัญชีของคุณผ่านการตรวจสอบ เปิดหอที่อนุมัติแล้วให้ค้นเจอได้',
                              style: text.bodySmall?.copyWith(color: OwnerColors.textBody),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                TitledCard(
                  title: 'เอกสารที่ส่งแล้ว',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ยังไม่มีข้อมูลเอกสาร', style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted)),
                      const SizedBox(height: 8),
                      Text(
                        'เอกสารเห็นได้เฉพาะคุณและ Admin เท่านั้น นักศึกษาจะไม่เห็น',
                        style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.page),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('ยังอัปโหลดเอกสารไม่ได้ ระบบนี้ยังไม่เปิดใช้งาน'))),
                  icon: const Icon(Icons.upload_file, size: 20),
                  label: const Text('อัปเดตเอกสาร'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
