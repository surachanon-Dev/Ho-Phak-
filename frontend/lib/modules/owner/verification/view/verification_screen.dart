import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../model/verification.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/verification_service.dart';
import '../../../../core/app_services.dart';
import '../../../../app/session.dart';
import '../../../auth/welcome/view/welcome_screen.dart';
import '../controller/verification_screen_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/owner_ui.dart';

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
      allowedExtensions: VerificationService.documentExtensions,
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
        const SnackBar(
          content: Text('Document sent. Waiting for admin review.'),
        ),
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

  ({Tone tone, IconData icon}) _statusLook(Verification? v) =>
      switch (v?.status) {
        VerificationStatus.approved => (
          tone: Tone.success,
          icon: Icons.verified_rounded,
        ),
        VerificationStatus.rejected => (
          tone: Tone.danger,
          icon: Icons.cancel_outlined,
        ),
        VerificationStatus.pending => (
          tone: Tone.warning,
          icon: Icons.hourglass_top_rounded,
        ),
        _ => (tone: Tone.neutral, icon: Icons.upload_file_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final v = _c.current;
    final look = _statusLook(v);
    final subtitle = _subtitle(v);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        automaticallyImplyLeading: !widget.gate,
      ),
      body: _c.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                OwnerBody(
                  maxWidth: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.gate) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 34,
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'You must verify your identity as a dorm owner before using the app.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // ---- สถานะปัจจุบัน ----
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        color: look.tone.bg,
                        borderColor: look.tone.fg.withValues(alpha: 0.25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(look.icon, color: look.tone.fg),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v == null
                                        ? 'No document sent yet'
                                        : VerificationStatus.label(v.status),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: look.tone.fg,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    DefaultTextStyle.merge(
                                      style: const TextStyle(
                                        color: AppColors.textBody,
                                        height: 1.45,
                                      ),
                                      child: subtitle,
                                    ),
                                  ],
                                  if (v?.documentUrl != null) ...[
                                    const SizedBox(height: 6),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.attach_file_rounded,
                                          size: 15,
                                          color: AppColors.textMuted,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Verification document sent',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_c.canSubmit)
                        Form(
                          key: _formKey,
                          child: AppCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SectionTitle(
                                  'Upload a document',
                                  icon: Icons.badge_outlined,
                                  subtitle: 'ID card or business licence · pdf, jpg, png, up to 10 MB',
                                ),
                                const SizedBox(height: 14),
                                Material(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    onTap: _c.saving ? null : _pick,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 22,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFC7CCF5),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            _c.picked == null
                                                ? Icons.cloud_upload_outlined
                                                : Icons.description_outlined,
                                            color: AppColors.primary,
                                            size: 30,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _c.picked == null
                                                ? 'Choose a document (pdf, jpg, png, up to 10 MB)'
                                                : _c.picked!.filename,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
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
                        ),
                      if (widget.gate) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                icon: const IconBadge(
                                  icon: Icons.logout_rounded,
                                  tone: Tone.danger,
                                  size: 48,
                                ),
                                title: const Text(
                                  'Log out?',
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  'You will need to sign in again to continue.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Log out'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            await widget.services.auth.logout();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                    WelcomeScreen(services: widget.services),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Log out'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
