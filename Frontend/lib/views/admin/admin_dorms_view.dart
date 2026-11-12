import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/dormitory.dart';
import '../../services/admin_service.dart';
import '../widgets/dorm_card.dart';
import 'admin_common.dart';
import 'admin_dorm_detail_view.dart';

/// Admin: all dormitories, filter by status + search by dorm / owner name
class AdminDormsView extends StatefulWidget {
  const AdminDormsView({super.key});

  @override
  State<AdminDormsView> createState() => _AdminDormsViewState();
}

class _AdminDormsViewState extends State<AdminDormsView> {
  String? _status = 'pending';
  String _q = '';
  late Future<List<Dormitory>> _future = _fetch();

  Future<List<Dormitory>> _fetch() => context.read<AdminService>().dorms(status: _status, q: _q);
  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ค้นหาชื่อหอพัก หรือ ชื่อเจ้าของ'),
          onSubmitted: (v) {
            _q = v;
            _reload();
          },
        ),
      ),
      FilterChips(options: dormStatusLabels, selected: _status, onSelected: (s) {
        _status = s;
        _reload();
      }),
      Expanded(
        child: AsyncList<Dormitory>(
          future: _future,
          onRetry: _reload,
          emptyText: 'ไม่มีหอพักในสถานะนี้',
          emptyIcon: Icons.apartment_outlined,
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => DormCard(
              dorm: list[i],
              showStatus: true,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDormDetailView(dormId: list[i].id)));
                _reload();
              },
            ),
          ),
        ),
      ),
    ]);
  }
}
