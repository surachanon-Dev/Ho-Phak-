import 'package:flutter/material.dart';

/// จำกัดความกว้างและชิดบนกลางจอ ให้หน้าดูเป็นขนาดมือถือแม้เปิดบนจอกว้าง
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// แสดง SnackBar สั้น ๆ ใช้ได้หลัง await เพราะเช็ก mounted ให้แล้ว
mixin Notifier<T extends StatefulWidget> on State<T> {
  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
