import 'package:flutter/material.dart';

import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/features/auth/register/register_controller.dart';
import 'package:hopak_frontend/features/auth/widgets/auth_widgets.dart';

/// หน้าสมัครสมาชิก: เลือกประเภท (นักศึกษา / เจ้าของหอพัก), ชื่อผู้ใช้, เบอร์โทร, รหัสผ่าน, ยืนยันรหัสผ่าน
/// สมัครสำเร็จแล้วปิดหน้านี้และส่งเบอร์กลับไปให้หน้าเข้าสู่ระบบเติมให้
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final RegisterController _c;
  String _role = 'student';

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
    for (final c in [_username, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.submit(
      RegisterInput(
        username: _username.text,
        phone: _phone.text,
        password: _password.text,
        confirmPassword: _confirm.text,
        role: _role,
      ),
    );
    if (!mounted) return;
    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('สมัครสมาชิกสำเร็จ'),
          content: const Text('เข้าสู่ระบบด้วยเบอร์โทรและรหัสผ่านที่สมัครไว้'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(_phone.text.trim());
    } else if (_c.failure != null) {
      showApiError(context, widget.services, _c.failure!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
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
                    const Center(child: HoPhakLogo(size: 64, showName: false)),
                    const SizedBox(height: 16),
                    Text(
                      'สร้างบัญชีผู้ใช้',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'student',
                          label: Text('นักศึกษา'),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: 'owner',
                          label: Text('เจ้าของหอพัก'),
                          icon: Icon(Icons.apartment),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: _c.loading ? null : (s) => setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register_username'),
                      controller: _username,
                      decoration: const InputDecoration(
                        hintText: 'ชื่อผู้ใช้',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: RegisterController.validateUsername,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('register_phone'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'เบอร์โทรศัพท์ *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: RegisterController.validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('register_password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'รหัสผ่าน (อย่างน้อย 8 ตัว) *',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: RegisterController.validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('register_confirm'),
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'ยืนยันรหัสผ่าน *',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => RegisterController.validateConfirm(v, _password.text),
                    ),
                    if (_role == 'owner')
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'ตอนเพิ่มหอพัก ต้องแนบรูปหอและเอกสารแสดงความเป็นเจ้าของ แล้วรอผู้ดูแลระบบอนุมัติ',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    if (_c.error != null) AuthFormError(_c.error!),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('register_submit'),
                      onPressed: _c.loading ? null : _submit,
                      child: _c.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('สมัครสมาชิก'),
                    ),
                    const SizedBox(height: 8),
                    AuthSwitchLink(
                      question: 'มีบัญชีอยู่แล้ว?',
                      action: 'เข้าสู่ระบบ',
                      onPressed: () => Navigator.of(context).maybePop(),
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
