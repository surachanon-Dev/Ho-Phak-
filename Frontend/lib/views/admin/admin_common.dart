import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../widgets/common.dart';

/// Runs an admin action, shows a snack and returns true on success
Future<bool> runAdmin(BuildContext context, Future<void> Function() action, String success) async {
  try {
    await action();
    if (context.mounted) showSnack(context, success);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
    return false;
  }
}

/// Asks for a reason first (required), then runs the action
Future<bool> runWithReason(BuildContext context, String title, Future<void> Function(String reason) action, String success,
    {String hint = 'เหตุผล (จะแจ้งให้ผู้ใช้ทราบ)'}) async {
  final reason = await askReason(context, title, hint: hint);
  if (reason == null || !context.mounted) return false;
  return runAdmin(context, () => action(reason), success);
}

/// Horizontal filter chips: null = all
class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.options, required this.selected, required this.onSelected, this.allLabel = 'ทั้งหมด'});
  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(label: Text(allLabel), selected: selected == null, onSelected: (_) => onSelected(null)),
          ),
          for (final e in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(label: Text(e.value), selected: selected == e.key, onSelected: (_) => onSelected(e.key)),
            ),
        ]),
      );
}

/// FutureBuilder with loading / error / empty states
class AsyncList<T> extends StatelessWidget {
  const AsyncList({super.key, required this.future, required this.onRetry, required this.builder, required this.emptyText, this.emptyIcon = Icons.inbox_outlined});
  final Future<List<T>> future;
  final VoidCallback onRetry;
  final Widget Function(List<T> items) builder;
  final String emptyText;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<T>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: onRetry);
          final items = snap.data!;
          if (items.isEmpty) return EmptyState(icon: emptyIcon, message: emptyText);
          return builder(items);
        },
      );
}
