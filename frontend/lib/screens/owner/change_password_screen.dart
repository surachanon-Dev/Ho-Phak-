import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';

/// เปลี่ยนรหัสผ่าน: รหัสเดิม + รหัสใหม่ + ยืนยัน (อย่างน้อย 8 ตัวอักษร)
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.services.extras.changePassword(
        current: _current.text,
        next: _next.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController c, String? Function(String?) v) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextFormField(controller: c, obscureText: true, validator: v),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  'Current password',
                  _current,
                  (v) => (v ?? '').isEmpty ? 'Enter your current password' : null,
                ),
                _field('New password', _next, (v) {
                  final t = v ?? '';
                  if (t.length < 8) return 'Use at least 8 characters';
                  if (t == _current.text) {
                    return 'New password must be different';
                  }
                  return null;
                }),
                _field(
                  'Confirm new password',
                  _confirm,
                  (v) => v == _next.text ? null : 'Passwords do not match',
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update password'),
                ),
                if (widget.services.extras.isLocal)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Demo mode: the password is checked here but not '
                      'changed on the server yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
