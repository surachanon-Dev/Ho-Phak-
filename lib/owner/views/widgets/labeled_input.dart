import 'package:flutter/material.dart';

import '../theme/owner_theme.dart';

/// ช่องกรอกที่มีป้ายชื่ออยู่ด้านบน
class LabeledInput extends StatelessWidget {
  const LabeledInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.error,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.maxLength,
    this.suffix,
    this.optional = false,
    this.action,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final int? maxLength;
  final Widget? suffix;
  final bool optional;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              text: label,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              children: [
                if (optional)
                  TextSpan(
                    text: '  · ไม่บังคับ',
                    style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            maxLines: obscure ? 1 : maxLines,
            maxLength: maxLength,
            textInputAction: action,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperMaxLines: 2,
              errorText: error,
              errorMaxLines: 2,
              suffixIcon: suffix,
              counterText: maxLength == null ? null : '',
            ),
          ),
        ),
      ],
    );
  }
}

/// ปุ่มหลักที่เปลี่ยนเป็นวงกลมหมุนระหว่างรอ
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tap = busy ? null : onPressed;
    if (busy) {
      return FilledButton(
        onPressed: tap,
        child: const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return icon == null
        ? FilledButton(onPressed: tap, child: Text(label))
        : FilledButton.icon(onPressed: tap, icon: Icon(icon, size: 20), label: Text(label));
  }
}
