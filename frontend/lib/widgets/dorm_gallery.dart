import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../model/dormitory.dart';
import '../modules/owner/widgets/owner_ui.dart' show DormCover;

/// รูปหอแบบเลื่อนดูได้ ใช้ร่วมกันทุก role
/// - ปัดนิ้ว / ลากด้วยเมาส์ / trackpad ได้ (ค่าเริ่มต้นของ Flutter บนเว็บลากด้วยเมาส์ไม่ได้)
/// - มีปุ่มลูกศรซ้าย-ขวาเมื่อมีมากกว่า 1 รูป
/// - ตัวนับรูปให้แต่ละหน้าวาดเองผ่าน [onPageChanged]
class DormGallery extends StatefulWidget {
  const DormGallery({super.key, required this.images, this.onPageChanged});

  final List<DormImage> images;
  final ValueChanged<int>? onPageChanged;

  @override
  State<DormGallery> createState() => _DormGalleryState();
}

class _DormGalleryState extends State<DormGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final count = images.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (i) {
              setState(() => _page = i);
              widget.onPageChanged?.call(i);
            },
            itemBuilder: (_, i) => DormCover(url: images[i].fullUrl, radius: 0),
          ),
        ),
        if (count > 1 && _page > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: _ArrowButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous photo',
              onTap: () => _go(_page - 1),
            ),
          ),
        if (count > 1 && _page < count - 1)
          Align(
            alignment: Alignment.centerRight,
            child: _ArrowButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next photo',
              onTap: () => _go(_page + 1),
            ),
          ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.black38,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white),
          onPressed: onTap,
        ),
      ),
    );
  }
}
