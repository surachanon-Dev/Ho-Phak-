import 'package:flutter/material.dart';

import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/features/student/widgets/student_widgets.dart';

/// หน้าเขียนรีวิว (ตาม review_form_view ของ Frontend-Big)
/// ส่งผ่าน [onSubmit] ซึ่งคืน true เมื่อสำเร็จ แล้วหน้าจะปิดพร้อมคืนค่า true
/// รีวิวจะแสดงหลังแอดมินตรวจสอบ (backend ตอบ 409 ถ้าเคยรีวิวหอนี้แล้ว)
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.dormName,
    required this.onSubmit,
  });

  final String dormName;
  final Future<bool> Function(int rating, String? body) onSubmit;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  int _rating = 0;
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาให้คะแนน 1-5 ดาว')),
      );
      return;
    }
    setState(() => _busy = true);
    final text = _body.text.trim();
    final ok = await widget.onSubmit(_rating, text.isEmpty ? null : text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เขียนรีวิว')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.dormName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text('ให้คะแนน', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('star_$i'),
                  iconSize: 40,
                  tooltip: '$i ดาว',
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: kStarColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'ความคิดเห็น (ไม่บังคับ)',
              alignLabelWithHint: true,
            ),
          ),
          const Text(
            'รีวิวจะแสดงหลังแอดมินตรวจสอบ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ส่งรีวิว'),
          ),
        ],
      ),
    );
  }
}
