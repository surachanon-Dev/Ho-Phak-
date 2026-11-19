import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/ui/ui.dart';

/// ระยะขอบซ้ายขวาของเนื้อหาในหน้าของแอดมิน
double adminPagePadding(BuildContext context) =>
    isWideLayout(context) ? 28 : 16;

/// โครงหน้าของแอดมินทุกแท็บ: หัวข้อ + คำอธิบาย + ปุ่มด้านขวา แล้วตามด้วยเนื้อหา
/// [child] ต้องจัดการการเลื่อนเอง (เช่น ListView ที่ใช้ [adminPagePadding])
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.toolbar,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// แถวตัวกรอง/ค้นหาใต้หัวข้อ
  final Widget? toolbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = adminPagePadding(context);
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: title,
                    subtitle: subtitle,
                    trailing: actions.isEmpty
                        ? null
                        : Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ),
                  if (toolbar != null) ...[
                    const SizedBox(height: 16),
                    toolbar!,
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// ปุ่มไอคอนมีกรอบ ใช้บนหัวข้อหน้า (เช่น รีเฟรช)
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      icon: Icon(icon, size: 20, color: AppColors.textBody),
    );
  }
}

/// ListView ที่เว้นขอบตามหน้าแอดมินและจำกัดความกว้างบนจอใหญ่
class AdminListView extends StatelessWidget {
  const AdminListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separator = 10,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separator;

  @override
  Widget build(BuildContext context) {
    final pad = adminPagePadding(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: separator),
      itemBuilder: (context, i) => ContentWidth(child: itemBuilder(context, i)),
    );
  }
}
