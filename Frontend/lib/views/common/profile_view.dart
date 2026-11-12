import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../student/favorites_view.dart';
import '../student/my_reviews_view.dart';
import '../widgets/common.dart';

/// Profile page shared by all roles (users table)
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();
    void push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                child: Text(user.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 30, color: AppColors.teal, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text(user.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
              Text('โทร ${user.phone}', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                Chip(label: Text(roleLabels[user.role] ?? user.role)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('แก้ไขข้อมูลส่วนตัว'),
              subtitle: const Text('ชื่อผู้ใช้ · เบอร์โทร'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editProfile(context, user.username ?? '', user.phone),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('เปลี่ยนรหัสผ่าน'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changePassword(context),
            ),
            if (user.isStudent) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('รายการโปรด'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const FavoritesView(standalone: true)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('รีวิวของฉัน'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const MyReviewsView()),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('logout_button'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
          icon: const Icon(Icons.logout),
          label: const Text('ออกจากระบบ'),
          onPressed: () async {
            if (!await confirmDialog(context, 'ออกจากระบบ', 'ต้องการออกจากระบบใช่หรือไม่?', danger: true)) return;
            if (!context.mounted) return;
            final auth = context.read<AuthController>();
            Navigator.of(context).popUntil((r) => r.isFirst);
            await auth.logout();
          },
        ),
      ],
    );
  }

  Future<void> _editProfile(BuildContext context, String username, String phone) async {
    final u = TextEditingController(text: username);
    final p = TextEditingController(text: phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขข้อมูลส่วนตัว'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: u, decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้')),
          const SizedBox(height: 8),
          TextField(controller: p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'เบอร์โทร')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final auth = context.read<AuthController>();
    final done = await auth.updateProfile(username: u.text, phone: p.text.trim());
    if (context.mounted) showSnack(context, done ? 'บันทึกแล้ว' : auth.error ?? 'บันทึกไม่สำเร็จ', error: !done);
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เปลี่ยนรหัสผ่าน'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่านปัจจุบัน')),
          const SizedBox(height: 8),
          TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่ (8 ตัวขึ้นไป)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('บันทึก')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final auth = context.read<AuthController>();
    final done = await auth.changePassword(current.text, next.text);
    if (context.mounted) showSnack(context, done ? 'เปลี่ยนรหัสผ่านสำเร็จ' : auth.error ?? 'ไม่สำเร็จ', error: !done);
  }
}
