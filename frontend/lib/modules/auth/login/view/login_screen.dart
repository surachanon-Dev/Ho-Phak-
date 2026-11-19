import 'package:flutter/material.dart';

import '../controller/login_controller.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';
import '../../../../app/home_router.dart';
import '../../register/view/register_screen.dart';
import '../../forgot_password/view/forgot_password_screen.dart';
import '../../widgets/auth_widgets.dart';

/// หน้าเข้าสู่ระบบ: ใช้ชื่อผู้ใช้หรือเบอร์โทร + รหัสผ่าน (ใช้ได้ทุก role)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.services, this.initialId});

  final AppServices services;

  /// เติมช่องชื่อผู้ใช้/เบอร์ไว้ให้ (เช่น เบอร์ที่เพิ่งสมัคร)
  final String? initialId;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _id = TextEditingController(text: widget.initialId);
  final _password = TextEditingController();
  late final LoginController _c;
  bool _obscure = true;

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
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.submit(phone: _id.text, password: _password.text);
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

  /// เปิดหน้าสมัครสมาชิก ถ้าสมัครสำเร็จจะได้เบอร์กลับมาเติมให้
  Future<void> _openRegister() async {
    final phone = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => RegisterScreen(services: widget.services)),
    );
    if (phone != null && mounted) {
      _id.text = phone;
      _password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // ลูกศรย้อนกลับขึ้นเองเมื่อมีหน้าก่อนหน้า (เช่น เปิดจากหน้าต้อนรับ)
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: HoPhakLogo()),
                    const SizedBox(height: 40),
                    Text(
                      'ยินดีต้อนรับกลับมา',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เข้าสู่ระบบด้วยชื่อผู้ใช้หรือเบอร์โทร',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('login_id'),
                      controller: _id,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'ชื่อผู้ใช้ หรือ เบอร์โทร',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: LoginController.validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('login_password'),
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'รหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: LoginController.validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('login_forgot'),
                        onPressed: _c.loading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              ),
                        child: const Text('ลืมรหัสผ่าน?'),
                      ),
                    ),
                    if (_c.error != null) AuthFormError(_c.error!),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('login_submit'),
                      onPressed: _c.loading ? null : _submit,
                      child: _c.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('เข้าสู่ระบบ'),
                    ),
                    const SizedBox(height: 12),
                    AuthSwitchLink(
                      question: 'ยังไม่มีบัญชี?',
                      action: 'สมัครสมาชิก',
                      onPressed: _c.loading ? null : _openRegister,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
