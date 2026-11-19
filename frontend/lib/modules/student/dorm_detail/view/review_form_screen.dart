import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../widgets/student_ui.dart';

/// หน้าเขียนรีวิว: ให้ดาว 1–5 และความคิดเห็น (ไม่บังคับ)
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
  static const _labels = ['', 'แย่มาก', 'พอใช้', 'ดี', 'ดีมาก', 'ยอดเยี่ยม'];

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาให้คะแนน 1-5 ดาว')));
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          StudentBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      const IconBadge(
                        icon: Icons.rate_review_outlined,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.dormName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ให้คะแนนหอพักนี้',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
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
                      SizedBox(
                        height: 22,
                        child: _rating == 0
                            ? null
                            : ToneBadge(
                                label: _labels[_rating],
                                tone: Tone.warning,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _body,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'ความคิดเห็น (ไม่บังคับ)',
                    hintText: 'เล่าประสบการณ์ของคุณ เช่น ความสะอาด ความปลอดภัย',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                const NoticeBanner(message: 'รีวิวจะแสดงหลังแอดมินตรวจสอบ'),
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
          ),
        ],
      ),
    );
  }
}
