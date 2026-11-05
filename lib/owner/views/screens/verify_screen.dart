import 'package:flutter/material.dart';

import '../theme/owner_theme.dart';
import '../widgets/labeled_input.dart';
import '../widgets/page_frame.dart';
import '../widgets/small_parts.dart';
import '../widgets/surface_card.dart';

/// สมัครสมาชิก ขั้นที่ 2: ยืนยันตัวตน (อัปโหลดเอกสารยังไม่เปิดใช้งาน)
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with Notifier<VerifyScreen> {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันตัวตน')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 8, OwnerGap.page, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepProgress(step: 2, caption: 'ขั้นที่ 2 จาก 2 · Admin จะตรวจสอบก่อนเปิดให้จัดการหอพัก'),
                const SizedBox(height: OwnerGap.block),
                SurfaceCard(
                  color: OwnerColors.primaryTint,
                  borderColor: OwnerColors.primaryTint,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: OwnerColors.primaryText),
                      const SizedBox(width: 12),
                      Text(
                        'สมัครสมาชิกสำเร็จ',
                        style: text.titleSmall?.copyWith(color: OwnerColors.primaryText, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                SurfaceCard(
                  color: OwnerColors.warningTint,
                  borderColor: OwnerColors.warningTint,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: OwnerColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รอยืนยันตัวตน',
                              style: text.titleSmall?.copyWith(color: OwnerColors.warning, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'เข้าสู่ระบบได้หลัง Admin ยืนยันบัญชีของคุณแล้ว',
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
                  title: 'เอกสารที่ต้องใช้',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• สำเนาบัตรประชาชนของเจ้าของ\n• เอกสารแสดงความเป็นเจ้าของ หรือสัญญาเช่าตึก',
                        style: text.bodyMedium?.copyWith(color: OwnerColors.textBody, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: OwnerColors.primaryTint,
                        borderRadius: BorderRadius.circular(OwnerRadius.card - 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(OwnerRadius.card - 4),
                          onTap: () => notify('ยังอัปโหลดเอกสารไม่ได้ ระบบนี้ยังไม่เปิดใช้งาน'),
                          child: SizedBox(
                            height: 110,
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.upload_file, color: OwnerColors.primaryText, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  'อัปโหลดเอกสาร',
                                  style: text.titleSmall?.copyWith(
                                    color: OwnerColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'JPG, PNG หรือ PDF · ไม่เกิน 5 MB',
                                  style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.page),
                BusyButton(label: 'ไปหน้าเข้าสู่ระบบ', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
