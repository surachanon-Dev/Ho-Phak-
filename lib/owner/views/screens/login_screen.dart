import 'package:flutter/material.dart';

import '../../controller/owner_controller.dart';
import '../theme/owner_theme.dart';
import '../widgets/labeled_input.dart';
import '../widgets/page_frame.dart';
import '../widgets/password_input.dart';
import '../widgets/surface_card.dart';
import 'owner_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with Notifier<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _username.text.trim();
    if (name.isEmpty || _password.text.isEmpty) {
      notify('กรอกชื่อผู้ใช้และรหัสผ่านให้ครบ');
      return;
    }
    setState(() => _busy = true);
    try {
      await OwnerController.login(name, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OwnerShell()));
    } on OwnerException catch (e) {
      notify(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Banner(text: text),
            // ดึงการ์ดขึ้นไปซ้อนบนแถบสีกรมท่า
            Transform.translate(
              offset: const Offset(0, -28),
              child: PageFrame(
                maxWidth: 440,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: OwnerGap.page),
                  child: Column(
                    children: [
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'เข้าสู่ระบบ',
                                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: OwnerColors.navy),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LabeledInput(
                              label: 'ชื่อผู้ใช้',
                              controller: _username,
                              hint: 'username',
                              action: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            PasswordInput(
                              label: 'รหัสผ่าน',
                              controller: _password,
                              hint: 'รหัสผ่าน',
                              action: TextInputAction.done,
                              onSubmitted: (_) => _busy ? null : _submit(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => notify('ยังไม่เปิดใช้งานการกู้รหัสผ่าน'),
                                child: const Text('ลืมรหัสผ่าน?'),
                              ),
                            ),
                            BusyButton(label: 'เข้าสู่ระบบ', busy: _busy, onPressed: _submit),
                            const SizedBox(height: 10),
                            Text(
                              'ลองใช้ได้ด้วย owner_test1 / password123',
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ยังไม่มีบัญชี?', style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted)),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('สมัครสมาชิก'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: OwnerColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(OwnerRadius.header)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(OwnerGap.page, 48, OwnerGap.page, 56),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: OwnerColors.primary,
                  borderRadius: BorderRadius.circular(OwnerRadius.card),
                ),
                child: const Icon(Icons.apartment, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 8),
              Text('Ho-Phak', style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              Text('สำหรับเจ้าของหอพัก', style: text.bodyMedium?.copyWith(color: const Color(0xFFC9D6E0))),
            ],
          ),
        ),
      ),
    );
  }
}
