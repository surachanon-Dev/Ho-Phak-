import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/verification.dart';
import '../services/api_client.dart';
import '../services/app_services.dart';
import '../ui/error_handling.dart';
import 'login_screen.dart';

/// หน้าการยืนยันตัวตนเจ้าของหอพัก
/// gate = true เมื่อยังไม่ได้ยืนยัน: แสดงเป็นหน้าหลักของแอปจนกว่าจะยืนยัน
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.services,
    this.gate = false,
  });

  final AppServices services;
  final bool gate;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  UploadFile? _picked;

  /// เลือกไฟล์เอกสาร (pdf, jpg, png) อ่านเป็น bytes เพื่อส่งแบบ multipart
  Future<void> _pick() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (f == null) return;
    final size = await f.length() ?? 0;
    if (size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(const SnackBar(content: Text('ไฟล์ใหญ่เกิน 10 MB')));
      }
      return;
    }
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() => _picked = UploadFile(bytes: bytes, filename: f.name));
  }

  Verification? _current;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final v = await widget.services.verification.current();
      if (mounted) setState(() => _current = v);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final file = _picked;
      if (file == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกไฟล์เอกสารก่อน')),
        );
        return;
      }
      await widget.services.verification.submit(file);
      setState(() => _picked = null);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งเอกสารแล้ว รอแอดมินตรวจสอบ')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _canSubmit =>
      _current == null || _current!.status == VerificationStatus.rejected;

  Widget? _subtitle(Verification? v) {
    if (v == null) return null;
    if (v.status == VerificationStatus.rejected && v.reason != null) {
      return Text('เหตุผล: ${v.reason}');
    }
    if (v.status == VerificationStatus.approved) {
      return const Text('ยืนยันแล้ว หากยังเข้าไม่ได้ ให้เข้าสู่ระบบใหม่');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final v = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('การยืนยันตัวตน'),
        automaticallyImplyLeading: !widget.gate,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.gate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'ต้องยืนยันตัวตนเจ้าของหอพักก่อนจึงจะใช้งานได้',
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(
                      v == null
                          ? 'ยังไม่ได้ส่งเอกสาร'
                          : VerificationStatus.label(v.status),
                    ),
                    subtitle: _subtitle(v),
                  ),
                ),
                if (v?.documentUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text('ส่งเอกสารยืนยันแล้ว'),
                  ),
                const SizedBox(height: 16),
                if (_canSubmit)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pick,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            _picked == null
                                ? 'เลือกไฟล์เอกสาร (pdf, jpg, png ไม่เกิน 10 MB)'
                                : _picked!.filename,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('ส่งเอกสาร'),
                        ),
                      ],
                    ),
                  ),
                if (widget.gate) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.services.auth.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              LoginScreen(services: widget.services),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                  ),
                ],
              ],
            ),
    );
  }
}
