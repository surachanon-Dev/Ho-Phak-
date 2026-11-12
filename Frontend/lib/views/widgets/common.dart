import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';

/// Ho-Phak logo (house icon in a teal rounded square)
class HoPhakLogo extends StatelessWidget {
  const HoPhakLogo({super.key, this.size = 64, this.showText = true, this.light = false});
  final double size;
  final bool showText;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.navy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(size * 0.28)),
          child: Icon(Icons.home_work_rounded, color: Colors.white, size: size * 0.6),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text('Ho-Phak', style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: color)),
          Text('Find your place, feel at home.', style: TextStyle(fontSize: 12, color: light ? Colors.white70 : AppColors.muted)),
        ],
      ],
    );
  }
}

/// Network image with placeholder (handles server-relative paths)
class NetImage extends StatelessWidget {
  const NetImage(this.path, {super.key, this.width, this.height, this.radius = 12, this.fit = BoxFit.cover});
  final String? path;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final src = path ?? '';
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFE3EAF0),
      child: const Icon(Icons.apartment_rounded, color: AppColors.muted, size: 36),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: switch (src) {
        '' => placeholder,
        // bundled demo photos
        _ when src.startsWith('assets/') =>
          Image.asset(src, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => placeholder),
        // real URLs (later, from the backend) and picked photos on web (blob:)
        _ when src.startsWith('http') || src.startsWith('blob:') || kIsWeb =>
          Image.network(src, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => placeholder),
        // photos picked from the phone's gallery (mock mode keeps the local path)
        _ => FutureBuilder(
            future: XFile(src).readAsBytes(),
            builder: (_, snap) => snap.hasData
                ? Image.memory(snap.data!, width: width, height: height, fit: fit)
                : placeholder,
          ),
      },
    );
  }
}

/// Coloured status label – works for dormitories / users
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.label});
  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'published' || 'approved' || 'active' => AppColors.success,
      'rejected' || 'suspended' => AppColors.danger,
      'hidden' => AppColors.muted,
      _ => AppColors.orange,
    };
    final text = label ?? dormStatusLabels[status] ?? approvalLabels[status] ?? userStatusLabels[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        message: message,
        action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('ลองใหม่')),
      );
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color = AppColors.teal});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class RatingText extends StatelessWidget {
  const RatingText({super.key, this.rating, this.count = 0});
  final num? rating;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 2),
          Text(rating == null ? 'ยังไม่มีรีวิว' : '${rating!.toStringAsFixed(1)} ($count)',
              style: const TextStyle(fontSize: 13, color: AppColors.text)),
        ],
      );
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.navy,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String confirm = 'ยืนยัน', bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger ? AppColors.danger : AppColors.teal,
            minimumSize: const Size(88, 40),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Asks the admin for a reason (rejection / suspension / hide). Returns null when cancelled.
Future<String?> askReason(BuildContext context, String title, {String hint = 'เหตุผล'}) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, autofocus: true, maxLines: 3, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
          onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, ctrl.text.trim());
          },
          child: const Text('ยืนยัน'),
        ),
      ],
    ),
  );
  return result;
}

/// Small row "icon + text" used in detail pages
class InfoRow extends StatelessWidget {
  const InfoRow(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

/// Orange / red / blue banner used for status explanations
class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.text, this.title, this.color = AppColors.orange, this.icon = Icons.info_outline, this.action});
  final String? title;
  final String text;
  final Color color;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        color: color.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) Text(title!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(text),
                    if (action != null) Padding(padding: const EdgeInsets.only(top: 6), child: action!),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 16});
  final int rating;
  final double size;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= rating ? Icons.star_rounded : Icons.star_border_rounded, size: size, color: Colors.amber),
      ]);
}
