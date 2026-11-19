import 'package:flutter/material.dart';

import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui/ui.dart';

/// ลืมรหัสผ่าน: ระบบยังไม่มีอีเมล/SMS ส่งรหัส จึงให้ติดต่อแอดมิน
/// แอดมินรีเซ็ตได้ในหน้ารายละเอียดผู้ใช้ (ได้รหัสชั่วคราวไปแจ้งผู้ใช้)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.services});

  final AppServices? services;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _steps = [
    (
      Icons.support_agent_rounded,
      'Contact an admin',
      'Tell them the phone number you use to sign in.',
    ),
    (
      Icons.key_rounded,
      'Get a temporary password',
      'The admin resets your password and gives you a temporary one.',
    ),
    (
      Icons.lock_reset_rounded,
      'Set a new password',
      'Sign in with the temporary password, then change it in Profile → Change password.',
    ),
  ];

  String? _adminPhone;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    final phone = await widget.services?.auth.supportContactPhone();
    if (!mounted) return;
    setState(() {
      _adminPhone = phone;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageHeader(
                    title: 'Reset your password',
                    subtitle:
                        'Ho-Phak cannot send reset codes by email or SMS yet. '
                        'An admin can reset your password for you.',
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < _steps.length; i++) ...[
                          if (i > 0) const Divider(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconBadge(icon: _steps[i].$1),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${i + 1}. ${_steps[i].$2}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _steps[i].$3,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_adminPhone != null)
                    NoticeBanner(
                      tone: Tone.info,
                      icon: Icons.phone_outlined,
                      title: 'Admin contact phone',
                      message: 'Call $_adminPhone for password reset assistance.',
                    )
                  else if (_loaded)
                    const NoticeBanner(
                      tone: Tone.warning,
                      message:
                          'Admin contact details have not been set yet. '
                          'Please ask your dorm or university staff.',
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
