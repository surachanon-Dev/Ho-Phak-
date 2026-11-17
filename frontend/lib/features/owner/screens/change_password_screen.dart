import 'package:flutter/material.dart';

import '../validation/owner_account_rules.dart';
import '../controllers/owner_account_screens_controllers.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handling.dart';

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
  late final ChangePasswordController _c;

  @override
  void initState() {
    super.initState();
    _c = ChangePasswordController(widget.services.account);
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _current.addListener(() => _c.setCurrent(_current.text));
    _next.addListener(() => _c.setNext(_next.text));
    _confirm.addListener(() => _c.setConfirm(_confirm.text));
  }

  @override
  void dispose() {
    _c.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.submit();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
      Navigator.of(context).pop();
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
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
                  OwnerAccountRules.currentPassword,
                ),
                _field(
                  'New password',
                  _next,
                  (v) => OwnerAccountRules.newPassword(v, current: _current.text),
                ),
                _field(
                  'Confirm new password',
                  _confirm,
                  (v) => OwnerAccountRules.confirmPassword(v, next: _next.text),
                ),
                FilledButton(
                  onPressed: _c.saving ? null : _save,
                  child: _c.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update password'),
                ),
                if (widget.services.account.isLocal)
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
