import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

/// Forgot password – verify identity with the phone number of the account:
/// 1) enter phone → OTP is sent   2) enter the 6-digit OTP   3) set a new password
/// Pops with the phone number when done (so the login screen can fill it in).
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _service = AuthService();
  final _phoneKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0; // 0 phone · 1 otp · 2 new password
  bool _busy = false;
  bool _obscure = true;
  String? _mockCode; // MOCK only – a real backend sends it by SMS
  String? _token;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_phone, _otp, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown--);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_step == 0 && !_phoneKey.currentState!.validate()) return;
    await _run(() async {
      final code = await _service.requestPasswordReset(_phone.text.trim());
      if (!mounted) return;
      setState(() {
        _mockCode = code;
        _step = 1;
        _otp.clear();
      });
      _startCooldown();
      showSnack(context, 'ส่งรหัส OTP ไปที่ ${_masked(_phone.text.trim())} แล้ว');
    });
  }

  Future<void> _verify() async {
    if (!_otpKey.currentState!.validate()) return;
    await _run(() async {
      final token = await _service.verifyResetOtp(_phone.text.trim(), _otp.text.trim());
      if (!mounted) return;
      setState(() {
        _token = token;
        _step = 2;
      });
    });
  }

  Future<void> _reset() async {
    if (!_passKey.currentState!.validate()) return;
    await _run(() async {
      await _service.resetPassword(_phone.text.trim(), _token!, _pass.text);
      if (!mounted) return;
      showSnack(context, 'เปลี่ยนรหัสผ่านสำเร็จ – เข้าสู่ระบบด้วยรหัสผ่านใหม่ได้เลย');
      Navigator.pop(context, _phone.text.trim());
    });
  }

  String _masked(String p) => p.length < 4 ? p : '${p.substring(0, 3)}-xxx-${p.substring(p.length - 4)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            _StepHeader(step: _step),
            const SizedBox(height: 24),
            switch (_step) {
              0 => _phoneStep(),
              1 => _otpStep(),
              _ => _passwordStep(),
            },
          ]),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onPressed, {Key? key}) => FilledButton(
        key: key,
        onPressed: _busy ? null : onPressed,
        child: _busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(text),
      );

  Widget _phoneStep() => Form(
        key: _phoneKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('กรอกเบอร์โทรที่ใช้สมัครบัญชี ระบบจะส่งรหัส OTP 6 หลักไปที่เบอร์นี้เพื่อยืนยันตัวตน',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('fp_phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(hintText: 'เบอร์โทร เช่น 0812345678', prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) => RegExp(r'^0[0-9]{8,9}$').hasMatch((v ?? '').trim()) ? null : 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก',
            onFieldSubmitted: (_) => _sendOtp(),
          ),
          const SizedBox(height: 20),
          _button('ส่งรหัส OTP', _sendOtp, key: const Key('fp_send')),
        ]),
      );

  Widget _otpStep() => Form(
        key: _otpKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('กรอกรหัส OTP 6 หลักที่ส่งไปที่ ${_masked(_phone.text.trim())} (หมดอายุใน 5 นาที)',
              style: const TextStyle(color: AppColors.muted)),
          if (_mockCode != null) ...[
            const SizedBox(height: 12),
            NoticeCard(
              icon: Icons.sms_outlined,
              color: AppColors.navy,
              title: 'โหมดจำลอง (ยังไม่มี SMS จริง)',
              text: 'รหัส OTP ของคุณคือ $_mockCode',
              action: TextButton(onPressed: () => _otp.text = _mockCode!, child: const Text('กรอกให้')),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('fp_otp'),
            controller: _otp,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: const InputDecoration(hintText: '••••••'),
            validator: (v) => (v ?? '').trim().length == 6 ? null : 'กรอกรหัส 6 หลัก',
            onFieldSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 20),
          _button('ยืนยันรหัส', _verify, key: const Key('fp_verify')),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: _busy || _cooldown > 0 ? null : _sendOtp,
              child: Text(_cooldown > 0 ? 'ส่งรหัสใหม่ได้ใน $_cooldown วินาที' : 'ส่งรหัสอีกครั้ง'),
            ),
            TextButton(onPressed: _busy ? null : () => setState(() => _step = 0), child: const Text('เปลี่ยนเบอร์')),
          ]),
        ]),
      );

  Widget _passwordStep() => Form(
        key: _passKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('ยืนยันตัวตนสำเร็จ ตั้งรหัสผ่านใหม่ได้เลย', style: TextStyle(color: AppColors.success)),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('fp_new'),
            controller: _pass,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v ?? '').length < 8 ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('fp_confirm'),
            controller: _confirm,
            obscureText: _obscure,
            decoration: const InputDecoration(hintText: 'ยืนยันรหัสผ่านใหม่', prefixIcon: Icon(Icons.lock_outline)),
            validator: (v) => v != _pass.text ? 'รหัสผ่านไม่ตรงกัน' : null,
            onFieldSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: 20),
          _button('บันทึกรหัสผ่านใหม่', _reset, key: const Key('fp_save')),
        ]),
      );
}

/// 1 เบอร์โทร → 2 OTP → 3 รหัสผ่านใหม่
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['เบอร์โทร', 'ยืนยัน OTP', 'รหัสผ่านใหม่'];
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        if (i > 0) Expanded(child: Divider(color: i <= step ? AppColors.teal : Colors.grey.shade300, thickness: 2)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: i <= step ? AppColors.teal : Colors.grey.shade300,
            child: i < step
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text('${i + 1}', style: TextStyle(color: i <= step ? Colors.white : AppColors.muted)),
          ),
          const SizedBox(height: 4),
          Text(labels[i], style: TextStyle(fontSize: 12, color: i <= step ? AppColors.navy : AppColors.muted)),
        ]),
      ],
    ]);
  }
}
