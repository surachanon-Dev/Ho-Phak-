import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../services/api_service.dart';
import 'dormitory_form_screen.dart';
import 'login_screen.dart';

class DormitoryListScreen extends StatefulWidget {
  const DormitoryListScreen({super.key});

  @override
  State<DormitoryListScreen> createState() => _DormitoryListScreenState();
}

class _DormitoryListScreenState extends State<DormitoryListScreen> {
  late Future<List<Dormitory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Dormitory>> _load() async {
    try {
      return await ApiService.fetchDormitories();
    } on ApiException catch (e) {
      // token หมดอายุหรือใช้ไม่ได้ ให้กลับไปหน้า login
      if (e.statusCode == 401) {
        await _backToLogin();
      }
      rethrow;
    }
  }

  void _reload() {
    // ห้ามให้ callback ของ setState คืนค่า Future จึงใช้ block แทน arrow
    setState(() {
      _future = _load();
    });
  }

  Future<void> _backToLogin() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    await _backToLogin();
  }

  Future<void> _openForm([Dormitory? dormitory]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DormitoryFormScreen(dormitory: dormitory)),
    );
    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(Dormitory dormitory) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบหอพัก'),
        content: Text('ต้องการลบ "${dormitory.name}" ใช่ไหม'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiService.deleteDormitory(dormitory.id);
      _reload();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หอพักของฉัน'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'ออกจากระบบ'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มหอพัก'),
      ),
      body: FutureBuilder<List<Dormitory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('ลองใหม่')),
                ],
              ),
            );
          }

          final dormitories = snapshot.data ?? [];
          if (dormitories.isEmpty) {
            return const Center(child: Text('ยังไม่มีหอพัก กดปุ่มเพิ่มหอพักเพื่อเริ่มต้น'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: dormitories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = dormitories[index];
              return Card(
                child: ListTile(
                  title: Text(d.name),
                  subtitle: Text('โซน ${d.zone} • ${d.pricePerMonth} บาท/เดือน'),
                  onTap: () => _openForm(d),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'ลบ',
                    onPressed: () => _confirmDelete(d),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
