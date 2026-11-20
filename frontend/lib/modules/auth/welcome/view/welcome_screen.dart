import 'package:flutter/material.dart';

import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui/ui.dart';
import '../../login/view/login_screen.dart';
import '../../register/view/register_screen.dart';

/// หน้าแรกก่อน login (หน้าที่เปิดเว็บมาเจอ)
/// จอแคบ: หัวไล่สี → จุดเด่น 3 ข้อ → สำหรับเจ้าของหอ → ปุ่ม
/// จอกว้าง: ซ้ายเป็นหัวไล่สีพร้อมปุ่ม ขวาเป็นจุดเด่นและส่วนของเจ้าของหอ
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.services});

  final AppServices services;

  static const _features = [
    (
      Icons.travel_explore_rounded,
      Tone.primary,
      'Find the right dorm',
      'Search by name, zone and monthly price, and see which dorms have free rooms.',
    ),
    (
      Icons.map_outlined,
      Tone.info,
      'See it on the map',
      'Check where each dorm is and how far it is from campus.',
    ),
    (
      Icons.forum_outlined,
      Tone.success,
      'Chat and read reviews',
      'Message the owner directly and read reviews from other students.',
    ),
  ];

  void _signIn(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LoginScreen(services: services)));

  void _signUp(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => RegisterScreen(services: services)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) =>
              c.maxWidth >= 900 ? _wide(context) : _narrow(context),
        ),
      ),
    );
  }

  Widget _narrow(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(
                  onSignIn: () => _signIn(context),
                  onSignUp: () => _signUp(context),
                ),
                const SizedBox(height: 24),
                const _SectionLabel('Why Ho-Phak'),
                const SizedBox(height: 10),
                for (final f in _features) ...[
                  _FeatureCard(icon: f.$1, tone: f.$2, title: f.$3, text: f.$4),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                const _OwnerCard(),
                const SizedBox(height: 20),
                const _Footer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _wide(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _Hero(
                        large: true,
                        onSignIn: () => _signIn(context),
                        onSignUp: () => _signUp(context),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _SectionLabel('Why Ho-Phak'),
                          const SizedBox(height: 10),
                          for (final f in _features) ...[
                            _FeatureCard(
                              icon: f.$1,
                              tone: f.$2,
                              title: f.$3,
                              text: f.$4,
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          const _OwnerCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// หัวไล่สี: โลโก้ ชื่อแอป คำอธิบาย ตัวเลขสั้น ๆ และปุ่มเข้าสู่ระบบ/สมัคร
class _Hero extends StatelessWidget {
  const _Hero({
    required this.onSignIn,
    required this.onSignUp,
    this.large = false,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 40 : 24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl + 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // วงกลมโปร่งตกแต่งมุมขวาบน
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: large ? 220 : 150,
              height: large ? 220 : 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x14FFFFFF),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ho-Phak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: large ? 48 : 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'For Mae Fah Luang University students',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome to Ho-Phak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 44 : 32,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find a dorm near campus, compare prices and rooms, '
                'and talk to the owner — all in one place.',
                style: TextStyle(
                  color: const Color(0xE6FFFFFF),
                  fontSize: large ? 17 : 15,
                  height: 1.5,
                ),
              ),
              SizedBox(height: large ? 32 : 24),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(Icons.place_outlined, '3 zones near campus'),
                  _HeroChip(Icons.verified_outlined, 'Owners checked by admin'),
                  _HeroChip(Icons.reviews_outlined, 'Real student reviews'),
                ],
              ),
              SizedBox(height: large ? 40 : 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: large ? 180 : double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: onSignIn,
                      child: const Text('Sign in'),
                    ),
                  ),
                  SizedBox(
                    width: large ? 200 : double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x99FFFFFF)),
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: onSignUp,
                      child: const Text('Create an account'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      border: Border.all(color: const Color(0x40FFFFFF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: icon, tone: tone, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// ส่วนสำหรับเจ้าของหอ: สมัครเป็นนักศึกษาก่อน แล้วสมัครเป็นเจ้าของในหน้าโปรไฟล์
class _OwnerCard extends StatelessWidget {
  const _OwnerCard();

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.primarySoft,
    borderColor: const Color(0xFFDCE1FB),
    padding: const EdgeInsets.all(16),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: Icons.home_work_outlined, tone: Tone.violet, size: 44),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Own a dorm?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Create an account, then choose "Become a dorm owner" in your '
                'profile. After an admin checks your identity, you can list '
                'your dorm for students.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Text(
    'Ho-Phak · Dorms near Mae Fah Luang University, Chiang Rai',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 12, color: AppColors.textFaint),
  );
}
