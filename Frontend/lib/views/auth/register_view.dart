import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';

/// Register: users.username (optional), users.phone (required, unique), password, role (student | owner)
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'student';

  @override
  void dispose() {
    for (final c in [_username, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.register(username: _username.text, phone: _phone.text.trim(), password: _password.text, role: _role);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      showSnack(context, auth.error ?? 'สมัครสมาชิกไม่สำเร็จ', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppColors.navy),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HoPhakLogo(size: 56, showText: false),
                    const SizedBox(height: 12),
                    const Text('สร้างบัญชีผู้ใช้',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'student', label: Text('นักศึกษา'), icon: Icon(Icons.school_outlined)),
                        ButtonSegment(value: 'owner', label: Text('เจ้าของหอพัก'), icon: Icon(Icons.apartment)),
                      ],
                      selected: {_role},
                      onSelectionChanged: (s) => setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(hintText: 'ชื่อผู้ใช้', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v ?? '').trim().length > 50 ? 'ไม่เกิน 50 ตัวอักษร' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'เบอร์โทรศัพท์ *', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) => RegExp(r'^0[0-9]{8,9}$').hasMatch((v ?? '').trim()) ? null : 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'รหัสผ่าน (อย่างน้อย 8 ตัว) *', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => (v ?? '').length < 8 ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'ยืนยันรหัสผ่าน *', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => v != _password.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                    ),
                    if (_role == 'owner')
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('เจ้าของหอต้องส่งเอกสารยืนยันตัวตนและรอผู้ดูแลระบบอนุมัติก่อน จึงจะเพิ่มหอพักได้',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('สมัครสมาชิก'),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('มีบัญชีอยู่แล้ว?'),
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('เข้าสู่ระบบ')),
                    ]),
                    const SizedBox(height: 24),
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
