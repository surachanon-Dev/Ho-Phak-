import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/ui/ui.dart';

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
}) {
  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x8C0F172A),
    builder: (_) => _ReasonDialog(
      title: title,
      message: message,
      hint: hint,
      confirmLabel: confirmLabel,
      icon: icon,
      tone: tone,
      maxLength: maxLength,
    ),
  );
}

/// ตัวป๊อปอัปเป็น StatefulWidget เพื่อให้ TextEditingController ถูก dispose
/// หลังป๊อปอัปปิดเสร็จจริง (ถ้า dispose ทันทีหลัง pop ช่องข้อความที่ยังเล่นแอนิเมชันปิดอยู่จะ error)
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.confirmLabel,
    required this.icon,
    required this.tone,
    required this.maxLength,
  });

  final String title;
  final String? message;
  final String hint;
  final String confirmLabel;
  final IconData icon;
  final Tone tone;
  final int maxLength;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context;
    final title = widget.title;
    final message = widget.message;
    final hint = widget.hint;
    final confirmLabel = widget.confirmLabel;
    final icon = widget.icon;
    final tone = widget.tone;
    final maxLength = widget.maxLength;
    return AlertDialog(
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
    );
  }
}
