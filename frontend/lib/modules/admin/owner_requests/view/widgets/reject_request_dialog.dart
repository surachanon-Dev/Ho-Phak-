import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../widgets/ui/ui.dart';

/// เหตุผลสำเร็จรูปให้แอดมินกดเลือกได้เร็ว
const _quickReasons = [
  'The document is blurry — please upload a clear photo of your business licence.',
  'The name on the document does not match your account.',
  'The document has expired. Please upload a current one.',
];

/// ป๊อปอัปกรอกเหตุผลตอน Reject คำขอ
/// คืนค่าเหตุผลที่ยืนยัน หรือ null ถ้ากดยกเลิก
Future<String?> showRejectRequestDialog(
  BuildContext context, {
  required String applicantName,
}) {
  final controller = TextEditingController(text: _quickReasons.first);

  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x8C0F172A),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentLength = controller.text.length;
          final canSubmit =
              controller.text.trim().isNotEmpty && currentLength <= 300;

          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBadge(
                      icon: Icons.person_off_outlined,
                      tone: Tone.danger,
                      size: 44,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Reject owner request?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$applicantName will see this reason in the app and can correct their details and resubmit.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Quick reasons',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (i, r) in _quickReasons.indexed)
                          ActionChip(
                            label: Text(
                              const ['Blurry', 'Name mismatch', 'Expired'][i],
                            ),
                            onPressed: () {
                              controller.text = r;
                              setDialogState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Reason (required)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      maxLength: 300,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(fontSize: 13.5, height: 1.4),
                      decoration: const InputDecoration(counterText: ''),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$currentLength / 300',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: canSubmit
                              ? () =>
                                    Navigator.of(ctx)
                                        .pop(controller.text.trim())
                              : null,
                          style: dangerButtonStyle(),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// ปุ่มยืนยันสีแดง (ใช้ ElevatedButton เพื่อแยกจากปุ่ม Filled ปกติ)
ButtonStyle dangerButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppColors.danger,
  foregroundColor: Colors.white,
  disabledBackgroundColor: const Color(0xFFF3C4C4),
  disabledForegroundColor: Colors.white,
  elevation: 0,
  minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  textStyle: const TextStyle(fontWeight: FontWeight.w700),
);

/// ปุ่มยืนยันสีหลัก แบบ ElevatedButton
ButtonStyle primaryElevatedStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  elevation: 0,
  minimumSize: const Size(0, 48),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  textStyle: const TextStyle(fontWeight: FontWeight.w700),
);
