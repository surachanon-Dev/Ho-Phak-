import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../models/dormitory.dart';
import '../../services/dorm_service.dart';
import '../widgets/common.dart';

/// Write / edit my review (reviews: rating 1-5, body optional, UNIQUE dormitory+user).
/// The review is shown right away (no admin moderation).
class ReviewFormView extends StatefulWidget {
  const ReviewFormView({super.key, required this.dorm, this.existing});
  final Dormitory dorm;
  final Review? existing;

  @override
  State<ReviewFormView> createState() => _ReviewFormViewState();
}

class _ReviewFormViewState extends State<ReviewFormView> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) return showSnack(context, 'กรุณาให้คะแนน 1-5 ดาว', error: true);
    setState(() => _busy = true);
    try {
      await context.read<DormService>().submitReview(widget.dorm.id, _rating, _body.text.trim().isEmpty ? null : _body.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.existing;
    return Scaffold(
      appBar: AppBar(title: Text(ex == null ? 'เขียนรีวิว' : 'แก้ไขรีวิว')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.dorm.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const SizedBox(height: 16),
        const Text('ให้คะแนน', style: TextStyle(fontWeight: FontWeight.w600)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              key: Key('star_$i'),
              iconSize: 40,
              onPressed: () => setState(() => _rating = i),
              icon: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber),
            ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: _body,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'ความคิดเห็น (ไม่บังคับ)', alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ส่งรีวิว'),
        ),
      ]),
    );
  }
}
