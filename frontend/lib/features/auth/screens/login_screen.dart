import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handling.dart';
import '../../../app/home_router.dart';
import 'register_screen.dart';

/// หน้า Sign In ตามดีไซน์: เข้าด้วยเบอร์โทรและรหัสผ่าน (ใช้ได้ทุก role)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late final LoginController _c;

  @override
  void initState() {
    super.initState();
    _c = LoginController(widget.services.auth);
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.submit(phone: _phone.text, password: _password.text);
    if (!mounted) return;
    if (ok) {
      final user = _c.user!;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeFor(widget.services, user)),
        (route) => false,
      );
    } else if (_c.failure != null) {
      showApiError(context, widget.services, _c.failure!);
    }
  }

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
                    'Sign In',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'เข้าสู่ระบบด้วยเบอร์โทรศัพท์',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text('เบอร์โทรศัพท์', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 16),
                  const Text('รหัสผ่าน', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'กรอกรหัสผ่าน'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                    onFieldSubmitted: (_) => _submit(),
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _c.loading ? null : _submit,
                    child: _c.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _c.loading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RegisterScreen(services: widget.services),
                              ),
                            ),
                      child: const Text('New here? Sign Up'),
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
