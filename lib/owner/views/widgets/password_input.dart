import 'package:flutter/material.dart';

import 'labeled_input.dart';

/// ช่องรหัสผ่านที่กดตาเพื่อแสดง/ซ่อนได้ ถ้าส่ง [visible] มา ผู้เรียกคุมสถานะเอง (ใช้กับสองช่องที่สลับพร้อมกัน)
class PasswordInput extends StatefulWidget {
  const PasswordInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.action,
    this.onChanged,
    this.onSubmitted,
    this.visible,
    this.onToggle,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool? visible;
  final VoidCallback? onToggle;

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _ownVisible = false;

  bool get _visible => widget.visible ?? _ownVisible;

  void _toggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() => _ownVisible = !_ownVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LabeledInput(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      error: widget.error,
      obscure: !_visible,
      action: widget.action,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        tooltip: _visible ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน',
        icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: _toggle,
      ),
    );
  }
}
