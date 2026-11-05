import 'package:flutter/material.dart';

import '../../controller/owner_session.dart';
import '../theme/owner_theme.dart';
import '../utils/formatters.dart';
import '../widgets/labeled_input.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface_card.dart';

/// แก้ไขอีเมลและเบอร์โทร ชื่อผู้ใช้เปลี่ยนไม่ได้เพราะใช้เข้าสู่ระบบ ปิดด้วย true เมื่อบันทึกแล้ว
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _username = TextEditingController(text: OwnerSession.username);
  final _email = TextEditingController(text: OwnerSession.contact.email);
  final _phone = TextEditingController(text: OwnerSession.contact.phone);
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    setState(() {
      _emailError = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
      _phoneError = RegExp(r'^0\d{9}$').hasMatch(phone) ? null : 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';
    });
    if (_emailError != null || _phoneError != null) return;

    OwnerSession.saveContact(OwnerSession.username, email: email, phone: phone);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขโปรไฟล์')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 8, OwnerGap.page, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: OwnerColors.primary,
                    child: Text(
                      firstLetter(OwnerSession.username),
                      style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ช่องนี้แก้ไม่ได้ จึงใช้ TextField ที่ปิดการแก้ไขโดยตรง
                      Text('ชื่อผู้ใช้ (Username)', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _username,
                        enabled: false,
                        decoration: const InputDecoration(
                          helperText: 'เปลี่ยนไม่ได้ เพราะใช้สำหรับเข้าสู่ระบบ',
                          fillColor: OwnerColors.divider,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'อีเมล',
                        controller: _email,
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'เบอร์โทรติดต่อ',
                        controller: _phone,
                        error: _phoneError,
                        keyboardType: TextInputType.phone,
                        helper: 'เบอร์นี้จะแสดงในทุกหอของคุณ',
                      ),
                      const SizedBox(height: 18),
                      BusyButton(label: 'บันทึก', onPressed: _save),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                Text(
                  'ข้อมูลเก็บไว้ในแอปชั่วคราว ปิดแอปแล้วจะหาย',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
