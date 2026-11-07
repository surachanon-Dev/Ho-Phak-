import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../ui/app_theme.dart';
import '../ui/error_handling.dart';

/// หน้า Sign Up ตามดีไซน์: ชื่อ, นามสกุล, เบอร์โทร, รหัสผ่าน, ยืนยันรหัสผ่าน
/// backend สร้างบัญชีเป็นนักศึกษาเสมอ ชื่อ-นามสกุลถูกส่งเป็น username
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _surname, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.services.auth.register(
        _phone.text.trim(),
        _password.text,
        _confirm.text,
        username: '${_first.text.trim()} ${_surname.text.trim()}',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign Up สำเร็จ'),
          content: const Text('เข้าสู่ระบบด้วยเบอร์โทรและรหัสผ่านที่สมัครไว้'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // เบอร์ซ้ำจะได้ 409 พร้อมข้อความจาก server แสดงใต้ฟอร์ม
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('เบอร์') || msg.contains('ถูกใช้')) {
        setState(() => _error = 'เบอร์โทรนี้ถูกใช้แล้ว');
      } else {
        showApiError(context, widget.services, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hopak'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign Up',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'สร้างบัญชีใหม่',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _label('ชื่อ'),
                  TextFormField(
                    controller: _first,
                    decoration: const InputDecoration(hintText: 'First name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณากรอกชื่อ'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('นามสกุล'),
                  TextFormField(
                    controller: _surname,
                    decoration: const InputDecoration(hintText: 'Surname'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณากรอกนามสกุล'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('เบอร์โทรศัพท์'),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '+66 000-0000000',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณากรอกเบอร์โทรศัพท์'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('รหัสผ่าน'),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter password',
                      helperText: 'อย่างน้อย 8 ตัวอักษร',
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('ยืนยันรหัสผ่าน'),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Confirm password',
                    ),
                    validator: (v) =>
                        v != _password.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Already have an account? Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
