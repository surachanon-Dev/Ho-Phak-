import 'package:flutter/material.dart';

import '../models/verification.dart';
import '../services/app_services.dart';
import '../ui/error_handling.dart';
import 'login_screen.dart';

/// หน้าการยืนยันตัวตนเจ้าของหอพัก
/// gate = true เมื่อยังไม่ได้ยืนยัน: แสดงเป็นหน้าหลักของแอปจนกว่าจะยืนยัน
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.services,
    this.gate = false,
  });

  final AppServices services;
  final bool gate;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docUrl = TextEditingController();
  Verification? _current;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _docUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final v = await widget.services.verification.current();
      if (mounted) setState(() => _current = v);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.services.verification.submit(_docUrl.text.trim());
      _docUrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งเอกสารแล้ว รอแอดมินตรวจสอบ')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _canSubmit =>
      _current == null || _current!.status == VerificationStatus.rejected;

  Widget? _subtitle(Verification? v) {
    if (v == null) return null;
    if (v.status == VerificationStatus.rejected && v.reason != null) {
      return Text('เหตุผล: ${v.reason}');
    }
    if (v.status == VerificationStatus.approved) {
      return const Text('ยืนยันแล้ว หากยังเข้าไม่ได้ ให้เข้าสู่ระบบใหม่');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final v = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('การยืนยันตัวตน'),
        automaticallyImplyLeading: !widget.gate,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.gate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'ต้องยืนยันตัวตนเจ้าของหอพักก่อนจึงจะใช้งานได้',
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(
                      v == null
                          ? 'ยังไม่ได้ส่งเอกสาร'
                          : VerificationStatus.label(v.status),
                    ),
                    subtitle: _subtitle(v),
                  ),
                ),
                if (v?.documentUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('เอกสารที่ส่งแล้ว: ${v!.documentUrl}'),
                  ),
                const SizedBox(height: 16),
                if (_canSubmit)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _docUrl,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'ลิงก์เอกสารยืนยัน',
                            hintText: 'https://...',
                            helperText: 'ยังไม่รองรับการอัปโหลดไฟล์ ให้กรอกลิงก์เอกสารไปก่อน',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'กรุณากรอกลิงก์เอกสาร';
                            return t.startsWith('http')
                                ? null
                                : 'ลิงก์ต้องขึ้นต้นด้วย http';
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('ส่งเอกสาร'),
                        ),
                      ],
                    ),
                  ),
                if (widget.gate) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.services.auth.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) =>
                              LoginScreen(services: widget.services),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                  ),
                ],
              ],
            ),
    );
  }
}
