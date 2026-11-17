import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/platform/open_document.dart';

/// เปิดดูเอกสารของแอดมิน: รูป png/jpg แสดงในกล่อง, PDF เปิดในแท็บใหม่ของเบราว์เซอร์
Future<void> showDocumentViewer(
  BuildContext context, {
  required String name,
  required Uint8List bytes,
}) async {
  // ตรวจชนิดไฟล์จากเนื้อไฟล์ก่อน เพราะชื่อที่ได้จากหอไม่มีนามสกุลเสมอ
  final isPdf =
      _startsWith(bytes, [0x25, 0x50, 0x44, 0x46]) ||
      RegExp(r"\.pdf$", caseSensitive: false).hasMatch(name);
  final isImage =
      _startsWith(bytes, [0x89, 0x50, 0x4E, 0x47]) ||
      _startsWith(bytes, [0xFF, 0xD8, 0xFF]) ||
      RegExp(r"\.(png|jpe?g)$", caseSensitive: false).hasMatch(name);
  final sizeKb = (bytes.length / 1024).toStringAsFixed(0);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(name),
      content: SizedBox(
        width: 520,
        child: isImage
            ? InteractiveViewer(child: Image.memory(bytes))
            : Text('$name ($sizeKb KB)'),
      ),
      actions: [
        if (isPdf)
          FilledButton(
            onPressed: () {
              if (!openPdfInNewTab(bytes)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('เปิด PDF ไม่ได้บนแพลตฟอร์มนี้'),
                  ),
                );
              }
            },
            child: const Text('Open PDF in new tab'),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

bool _startsWith(Uint8List bytes, List<int> magic) {
  if (bytes.length < magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic[i]) return false;
  }
  return true;
}
