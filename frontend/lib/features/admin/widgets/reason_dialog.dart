import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ui/ui.dart';

/// ป๊อปอัปขอเหตุผลก่อนทำรายการ (ปฏิเสธ/ระงับ) คืน null ถ้ากดยกเลิก
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  String? message,
  String hint = 'Reason (required)',
  String confirmLabel = 'Confirm',
  IconData icon = Icons.report_gmailerrorred_rounded,
  Tone tone = Tone.danger,
  int maxLength = 300,
}) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    barrierColor: const Color(0x8C0F172A),
    builder: (ctx) => AlertDialog(
      icon: IconBadge(icon: icon, tone: tone, size: 44),
      title: Text(title, textAlign: TextAlign.center),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: maxLength,
              decoration: InputDecoration(hintText: hint),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tone == Tone.danger
                ? AppColors.danger
                : AppColors.primary,
          ),
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return reason;
}
