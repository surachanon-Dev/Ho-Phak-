import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/platform/open_document.dart';

/// เปิดดูเอกสารของแอดมิน: รูป png/jpg แสดงในกล่อง, PDF เปิดในแท็บใหม่ของเบราว์เซอร์
Future<void> showDocumentViewer(
  BuildContext context, {
  required String name,
  required Uint8List bytes,
}) async {
  final isImage = RegExp(r'\.(png|jpe?g)$', caseSensitive: false).hasMatch(name);
  final isPdf = RegExp(r'\.pdf$', caseSensitive: false).hasMatch(name);
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
                  const SnackBar(content: Text('เปิด PDF ไม่ได้บนแพลตฟอร์มนี้')),
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
