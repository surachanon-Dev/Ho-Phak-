import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import 'forgot_password_view.dart';
import 'register_view.dart';

/// Login for every role – the app opens the Student / Owner / Admin area based on the JWT role.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.login(_id.text, _password.text);
    if (!ok && mounted) showSnack(context, auth.error ?? 'เข้าสู่ระบบไม่สำเร็จ', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HoPhakLogo(size: 72),
                    const SizedBox(height: 28),
                    const Text('ยินดีต้อนรับกลับมา',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const Text('เข้าสู่ระบบด้วยชื่อผู้ใช้หรือเบอร์โทร', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('login_id'),
                      controller: _id,
                      decoration: const InputDecoration(hintText: 'ชื่อผู้ใช้ หรือ เบอร์โทร', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อผู้ใช้หรือเบอร์โทร' : null,
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
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('forgot_password'),
                        onPressed: () async {
                          final phone = await Navigator.push<String>(
                              context, MaterialPageRoute(builder: (_) => const ForgotPasswordView()));
                          if (phone != null && mounted) {
                            _id.text = phone; // fill the phone, the user types the new password
                            _password.clear();
                          }
                        },
                        child: const Text('ลืมรหัสผ่าน?'),
                      ),
                    ),
                    FilledButton(
                      key: const Key('login_submit'),
                      onPressed: auth.busy ? null : _submit,
                      child: auth.busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('เข้าสู่ระบบ'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ยังไม่มีบัญชี?'),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView())),
                          child: const Text('สมัครสมาชิก'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DemoAccounts(onPick: (email, password) {
                      _id.text = email;
                      _password.text = password;
                    }),
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

/// MOCK MODE helper – tap a role to fill the demo login
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});
  final void Function(String email, String password) onPick;

  static const _accounts = [
    ('นักศึกษา (Frame)', Icons.school_outlined, 'Frame', 'Pass@1234'),
    ('เจ้าของหอ (Bank)', Icons.apartment, 'Bank', 'Pass@1234'),
    ('เจ้าของหอ (Big)', Icons.home_work_outlined, 'Big', 'Pass@1234'),
    ('ผู้ดูแลระบบ', Icons.admin_panel_settings_outlined, 'admin', 'Pass@1234'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.orange.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('โหมดจำลอง (ยังไม่เชื่อม backend) – แตะเพื่อเลือกบัญชีทดสอบ',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, icon, email, password) in _accounts)
                  ActionChip(
                    avatar: Icon(icon, size: 18, color: AppColors.teal),
                    label: Text(label),
                    onPressed: () => onPick(email, password),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
