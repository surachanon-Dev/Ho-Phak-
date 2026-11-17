import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../shared/models/verification.dart';
import '../../../core/network/api_client.dart';
import '../controllers/owner_review_and_verification_controllers.dart';
import '../controllers/verification_controller.dart';
import '../../../core/app_services.dart';
import '../../../core/utils/error_handling.dart';
import '../../auth/screens/login_screen.dart';

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
  late final VerificationScreenController _c;

  @override
  void initState() {
    super.initState();
    _c = VerificationScreenController(widget.services.verification);
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// เลือกไฟล์เอกสาร (pdf, jpg, png) อ่านเป็น bytes เพื่อส่งแบบ multipart
  Future<void> _pick() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: VerificationController.documentExtensions,
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    final ok = _c.pick(UploadFile(bytes: bytes, filename: f.name));
    if (!ok && _c.pickError != null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(_c.pickError!)));
    }
  }

  Future<void> _load() async {
    final ok = await _c.load();
    if (!ok && mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_c.picked == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Please choose a document first')),
      );
      return;
    }
    final ok = await _c.submit();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document sent. Waiting for admin review.')),
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Widget? _subtitle(Verification? v) {
    if (v == null) return null;
    if (v.status == VerificationStatus.rejected && v.reason != null) {
      return Text('Reason: ${v.reason}');
    }
    if (v.status == VerificationStatus.approved) {
      return const Text('Verified. If you still cannot get in, sign in again.');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        automaticallyImplyLeading: !widget.gate,
      ),
      body: _c.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.gate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'You must verify your identity as a dorm owner before using the app.',
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(
                      v == null
                          ? 'No document sent yet'
                          : VerificationStatus.label(v.status),
                    ),
                    subtitle: _subtitle(v),
                  ),
                ),
                if (v?.documentUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text('Verification document sent'),
                  ),
                const SizedBox(height: 16),
                if (_c.canSubmit)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _c.saving ? null : _pick,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            _c.picked == null
                                ? 'Choose a document (pdf, jpg, png, up to 10 MB)'
                                : _c.picked!.filename,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _c.saving ? null : _submit,
                          child: _c.saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send document'),
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
                    label: const Text('Sign out'),
                  ),
                ],
              ],
            ),
    );
  }
}
