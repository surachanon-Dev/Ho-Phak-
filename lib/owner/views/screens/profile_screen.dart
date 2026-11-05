import 'package:flutter/material.dart';

import '../../controller/owner_session.dart';
import '../theme/owner_theme.dart';
import '../utils/formatters.dart';
import '../widgets/page_frame.dart';
import '../widgets/small_parts.dart';
import '../widgets/surface_card.dart';
import 'edit_profile_screen.dart';
import 'verify_docs_screen.dart';

/// โปรไฟล์ของ owner เมนูที่ยังไม่มีระบบรองรับ (รหัสผ่าน ธีมมืด ภาษา ติดต่อ Admin) แสดงเป็นรายการที่กดไม่ได้
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = OwnerSession.username;
    final contact = OwnerSession.contact;
    final contactLine = [
      if (contact.email.isNotEmpty) contact.email,
      if (contact.phone.isNotEmpty) phoneWithDashes(contact.phone),
    ].join(' · ');

    return SafeArea(
      bottom: false,
      child: PageFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(OwnerGap.page, 24, OwnerGap.page, OwnerGap.belowNav),
          children: [
            Semantics(
              header: true,
              child: Text(
                'โปรไฟล์',
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: OwnerColors.navy),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: OwnerColors.primary,
                child: Text(
                  firstLetter(name),
                  style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(name, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (contactLine.isNotEmpty)
              Text(
                contactLine,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: OwnerColors.textMuted),
              ),
            const SizedBox(height: 8),
            const Center(child: Pill('ยืนยันตัวตนแล้ว')),
            const SizedBox(height: 16),
            _Menu([
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('แก้ไขโปรไฟล์'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _edit,
              ),
              const _Unavailable(icon: Icons.lock_outline, title: 'เปลี่ยนรหัสผ่าน'),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('เอกสารยืนยันตัวตน'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const VerifyDocsScreen())),
              ),
            ]),
            const SizedBox(height: OwnerGap.block),
            _Menu([
              const _Unavailable(
                icon: Icons.dark_mode_outlined,
                title: 'โหมดมืด',
                trailing: Switch(value: false, onChanged: null),
              ),
              _Unavailable(
                icon: Icons.language,
                title: 'ภาษา',
                trailing: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'th', label: Text('ไทย')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: const {'th'},
                  onSelectionChanged: null,
                ),
              ),
              const _Unavailable(icon: Icons.chat_bubble_outline, title: 'ติดต่อผู้ดูแลระบบ'),
            ]),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: OwnerColors.danger,
                side: const BorderSide(color: OwnerColors.danger),
              ),
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// กรอบขาวที่เรียงรายการเมนู คั่นด้วยเส้นบาง ๆ
class _Menu extends StatelessWidget {
  const _Menu(this.items);

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(),
            items[i],
          ],
        ],
      ),
    );
  }
}

/// รายการเมนูที่ยังไม่เปิดใช้งาน แสดงจางลงและกดไม่ได้
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Opacity(
      opacity: 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.bodyLarge),
                  Text('ยังไม่เปิดใช้งาน', style: text.bodySmall),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
