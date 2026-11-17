import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hopak_frontend/features/owner/validation/owner_account_rules.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/features/owner/models/owner_profile.dart';
import 'package:hopak_frontend/features/owner/controllers/edit_profile_controller.dart';

/// แก้โปรไฟล์ (Figma O-8a): ชื่อ, นามสกุล, เบอร์, รหัสผ่าน (ใช้เมื่อเปลี่ยนเบอร์), รูป
/// pop(true) เมื่อบันทึกแล้ว
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.services,
    required this.profile,
  });

  final AppServices services;
  final OwnerProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _surname;
  late final TextEditingController _phone;
  final _password = TextEditingController();
  late final EditProfileController _c;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _c = EditProfileController(original: p, account: widget.services.account);
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _first = TextEditingController(text: p.firstName)
      ..addListener(() => _c.setFirstName(_first.text));
    _surname = TextEditingController(text: p.surname)
      ..addListener(() => _c.setSurname(_surname.text));
    _phone = TextEditingController(text: p.phone)
      ..addListener(() => _c.setPhone(_phone.text));
    _password.addListener(() => _c.setPassword(_password.text));
  }

  @override
  void dispose() {
    _c.dispose();
    for (final c in [_first, _surname, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    _c.setPhoto(base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.save();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Widget _labeled(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      field,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pending = widget.profile.pendingPhone;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      ProfileAvatar(photoBase64: _c.photo, size: 96),
                      TextButton(
                        onPressed: _pickPhoto,
                        child: const Text('Change photo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _labeled(
                  'First name',
                  TextFormField(
                    controller: _first,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your first name'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Surname',
                  TextFormField(
                    controller: _surname,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your surname'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _labeled(
                  'Phone number',
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: (_) => _c.validatePhone(),
                  ),
                ),
                if (pending != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'New number $pending is waiting for admin approval. '
                      'You still sign in with ${widget.profile.phone}.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _labeled(
                  'Password',
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    validator: (v) => OwnerAccountRules.passwordForPhoneChange(
                      v,
                      phoneChanged: _c.phoneChanged,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Needed only when you change your phone number',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _c.canSave ? _save : null,
                  child: _c.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
                if (!_c.dirty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Save is enabled after you change something',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// รูปโปรไฟล์วงกลม (ไม่มีรูป = ไอคอนคน)
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.photoBase64, this.size = 96});

  final String? photoBase64;
  final double size;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photoBase64!));
      } catch (_) {
        image = null;
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image == null
          ? Icon(
              Icons.person_outline,
              size: size * 0.46,
              color: AppColors.textMuted,
            )
          : null,
    );
  }
}
