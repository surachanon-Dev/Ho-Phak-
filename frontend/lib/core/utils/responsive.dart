import 'package:flutter/material.dart';

/// ความกว้างหน้าจอขั้นต่ำที่ใช้ layout แบบเดสก์ท็อป (sidebar ถาวร)
/// แคบกว่านี้ (มือถือ/แท็บเล็ตแนวตั้ง) ใช้เมนูแบบ drawer แทน
const double kWideLayoutBreakpoint = 900;

/// true เมื่อหน้าจอกว้างพอสำหรับ layout เดสก์ท็อป
bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;

/// ให้เนื้อหาไม่ถูกบีบเกินความกว้างขั้นต่ำ ถ้าพื้นที่แคบกว่าจะเลื่อนแนวนอนได้
/// (ใช้กับตารางที่มีหลายคอลัมน์ ไม่ให้ข้อความหักทีละตัวอักษรหรือ overflow)
class MinWidthScroll extends StatelessWidget {
  const MinWidthScroll({
    super.key,
    required this.minWidth,
    required this.child,
  });

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}

/// แถวการ์ดที่เรียงแนวนอนบนจอกว้าง และซ้อนแนวตั้งเมื่อพื้นที่แคบ
/// รับ [row] ที่ลูกเป็น Expanded คั่นด้วย SizedBox(width) ตามเดิม แล้วแปลงให้อัตโนมัติ
class StackOnNarrow extends StatelessWidget {
  const StackOnNarrow({super.key, required this.row, this.breakpoint = 640});

  final Row row;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) return row;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in row.children)
              if (child is Expanded)
                child.child
              else if (child is SizedBox &&
                  child.width != null &&
                  child.height == null)
                SizedBox(height: child.width)
              else
                child,
          ],
        );
      },
    );
  }
}
