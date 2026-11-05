import 'package:flutter/material.dart';

import '../../controller/owner_controller.dart';
import '../../controller/owner_session.dart';
import '../theme/owner_theme.dart';
import '../widgets/labeled_input.dart';
import '../widgets/page_frame.dart';
import '../widgets/password_input.dart';
import '../widgets/small_parts.dart';
import '../widgets/surface_card.dart';
import 'verify_screen.dart';

/// สมัครสมาชิก ขั้นที่ 1: ข้อมูลบัญชี
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with Notifier<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _accepted = false;
  bool _showPasswords = false;

  /// ข้อความ error ของแต่ละช่อง (key = ชื่อช่อง) ว่าง = ผ่าน
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_username, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _check() {
    final name = _username.text.trim();
    final password = _password.text;
    return {
      if (name.length < 3 || name.length > 50) 'username': 'ชื่อผู้ใช้ต้องยาว 3–50 ตัวอักษร',
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) 'email': 'รูปแบบอีเมลไม่ถูกต้อง',
      if (!RegExp(r'^0\d{9}$').hasMatch(_phone.text.trim())) 'phone': 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0',
      if (password.length < 8) 'password': 'รหัสผ่านต้องยาวอย่างน้อย 8 ตัวอักษร',
      if (_confirm.text != password) 'confirm': 'รหัสผ่านไม่ตรงกัน',
      if (!_accepted) 'terms': 'ต้องยอมรับเงื่อนไขก่อนสมัคร',
    };
  }

  Future<void> _submit() async {
    final errors = _check();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _busy = true);
    try {
      final name = _username.text.trim();
      await OwnerController.register(name, _password.text);
      OwnerSession.saveContact(name, email: _email.text.trim(), phone: _phone.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VerifyScreen()));
    } on OwnerException catch (e) {
      notify(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 0 ยังไม่กรอก · 1 อ่อน · 2 พอใช้ · 3 แข็งแรง
  int get _strength {
    final p = _password.text;
    if (p.isEmpty) return 0;
    if (p.length < 8) return 1;
    final mixed = RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);
    return p.length >= 12 && mixed ? 3 : 2;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strength = _strength;
    final strengthColor = strength == 1 ? OwnerColors.danger : OwnerColors.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิกเจ้าของหอ')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 8, OwnerGap.page, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepProgress(step: 1, caption: 'ขั้นที่ 1 จาก 2 · ข้อมูลบัญชี'),
                const SizedBox(height: OwnerGap.block),
                SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledInput(
                        label: 'ชื่อผู้ใช้ (Username)',
                        controller: _username,
                        hint: '3–50 ตัวอักษร',
                        error: _errors['username'],
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'อีเมล',
                        controller: _email,
                        hint: 'you@example.com',
                        error: _errors['email'],
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'เบอร์โทรติดต่อ',
                        controller: _phone,
                        hint: '0812345678',
                        helper: 'นักศึกษาจะเห็นเบอร์นี้ในหน้ารายละเอียดหอ',
                        error: _errors['phone'],
                        keyboardType: TextInputType.phone,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      PasswordInput(
                        label: 'รหัสผ่าน',
                        controller: _password,
                        hint: 'อย่างน้อย 8 ตัวอักษร',
                        error: _errors['password'],
                        action: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        visible: _showPasswords,
                        onToggle: () => setState(() => _showPasswords = !_showPasswords),
                      ),
                      if (strength > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var i = 1; i <= 3; i++) ...[
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i <= strength ? strengthColor : OwnerColors.fieldBorder,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              const ['', 'อ่อน', 'พอใช้', 'แข็งแรง'][strength],
                              style: text.bodySmall?.copyWith(color: strengthColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      PasswordInput(
                        label: 'ยืนยันรหัสผ่าน',
                        controller: _confirm,
                        hint: 'พิมพ์รหัสผ่านอีกครั้ง',
                        error: _errors['confirm'],
                        action: TextInputAction.done,
                        visible: _showPasswords,
                        onToggle: () => setState(() => _showPasswords = !_showPasswords),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _accepted,
                        onChanged: (v) => setState(() => _accepted = v ?? false),
                        title: Text('ยอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว (PDPA)', style: text.bodyMedium),
                      ),
                      if (_errors['terms'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_errors['terms']!, style: text.bodySmall?.copyWith(color: OwnerColors.danger)),
                        ),
                      const SizedBox(height: 8),
                      BusyButton(label: 'ถัดไป: ยืนยันตัวตน', busy: _busy, onPressed: _submit),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('มีบัญชีแล้ว?', style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted)),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('เข้าสู่ระบบ')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
