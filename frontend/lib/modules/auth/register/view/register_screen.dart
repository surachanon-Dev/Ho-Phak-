import 'package:flutter/material.dart';

import '../controller/register_controller.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';

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
  late final RegisterController _c;

  @override
  void initState() {
    super.initState();
    _c = RegisterController(widget.services.auth);
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    for (final c in [_first, _surname, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.submit(
      RegisterInput(
        firstName: _first.text,
        surname: _surname.text,
        phone: _phone.text,
        password: _password.text,
        confirmPassword: _confirm.text,
      ),
    );
    if (!mounted) return;
    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign up complete'),
          content: const Text(
            'Sign in with the phone number and password you registered.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } else if (_c.failure != null) {
      showApiError(context, widget.services, _c.failure!);
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
                    'Create a new account',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _label('First name'),
                  TextFormField(
                    controller: _first,
                    decoration: const InputDecoration(hintText: 'First name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your first name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Last name'),
                  TextFormField(
                    controller: _surname,
                    decoration: const InputDecoration(hintText: 'Surname'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your last name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Phone number'),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '+66 000-0000000',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your phone number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Password'),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter password',
                      helperText: 'At least 8 characters',
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Confirm password'),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Confirm password',
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                  ),
                  if (_c.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _c.error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _c.loading ? null : _submit,
                    child: _c.loading
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
