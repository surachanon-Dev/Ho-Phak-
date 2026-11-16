import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/error_handling.dart';

// ============================================================================
// 1. หน้า AMENITIES (สิ่งอำนวยความสะดวก)
// ============================================================================

class AdminAmenitiesTab extends StatefulWidget {
  const AdminAmenitiesTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminAmenitiesTab> createState() => _AdminAmenitiesTabState();
}

class _AdminAmenitiesTabState extends State<AdminAmenitiesTab> {
  late final AdminService _admin = AdminService(widget.services.api);
  
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // ข้อมูลจำลองตามแบบหน้าจอ Amenities
      final items = [
        {'id': 1, 'name': 'Pets allowed', 'used_by': 3, 'added': 'Seed (D-45)'},
        {'id': 2, 'name': 'Parking', 'used_by': 7, 'added': 'Seed (D-45)'},
        {'id': 3, 'name': 'Washing machine', 'used_by': 5, 'added': 'Seed (D-45)'},
        {'id': 4, 'name': 'Elevator', 'used_by': 2, 'added': 'Yesterday'},
        {'id': 5, 'name': 'Wi-Fi', 'used_by': 11, 'added': '1 Nov 2026'},
        {'id': 6, 'name': 'CCTV', 'used_by': 6, 'added': '1 Nov 2026'},
        {'id': 7, 'name': 'Key card', 'used_by': 4, 'added': '1 Nov 2026'},
      ];
      
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog([Map<String, dynamic>? amenity]) async {
    final isEdit = amenity != null;
    final controller = TextEditingController(text: isEdit ? amenity['name'] : '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit amenity' : 'Add amenity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Names must be unique. Editing a name updates every dorm that uses it.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      _load();
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> amenity) async {
    final name = amenity['name'];
    final usedBy = amenity['used_by'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Delete amenity?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '"$name" is used by $usedBy dorms. It will be removed from those dorms too. This cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Amenities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text('Sun 8 Nov 2026', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          )
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Owners pick from this list when they add or edit a dorm.', 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    FilledButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add amenity'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    _buildTableHeader(),
                    ..._items.map((item) => _buildTableRow(item)).toList(),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Text('USED BY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Text('ADDED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
          const SizedBox(width: 100), 
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('${item['used_by']} dorms', style: TextStyle(color: Colors.grey.shade700))),
          Expanded(flex: 2, child: Text(item['added'].toString(), style: TextStyle(color: Colors.grey.shade700))),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showAddEditDialog(item),
                  child: const Text('Edit', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => _showDeleteDialog(item),
                  child: const Text('Delete', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. หน้า ACTIVITY LOG (ประวัติการกระทำ)
// ============================================================================

class AdminLogsTab extends StatefulWidget {
  const AdminLogsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends State<AdminLogsTab> {
  late final AdminService _admin = AdminService(widget.services.api);
  
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // ข้อมูลจำลองตามแบบหน้าจอ Activity log
      final items = [
        {'time': 'Today 09:42', 'admin': 'Admin', 'action': 'dormitory.approve', 'target': 'Dorm · หอพักบ้านสวนดอย', 'details': '—'},
        {'time': 'Today 09:15', 'admin': 'Admin', 'action': 'review.hide', 'target': 'Review #31', 'details': 'Advertising another place'},
        {'time': 'Yesterday 17:03', 'admin': 'Admin', 'action': 'owner.approve', 'target': 'User · Kanya Srisuk', 'details': 'Role student → owner'},
        {'time': 'Yesterday 16:40', 'admin': 'Admin', 'action': 'dormitory.suspend', 'target': 'Dorm · หอพักสวนหลวง', 'details': 'Price shown is wrong'},
        {'time': 'Yesterday 14:22', 'admin': 'Admin', 'action': 'revision.reject', 'target': 'Dorm · บ้านลอยงาม', 'details': 'Photos are not of this building'},
        {'time': 'Yesterday 11:20', 'admin': 'Admin', 'action': 'amenity.create', 'target': 'Amenity · Elevator', 'details': '—'},
        {'time': '7 Nov 2026 18:05', 'admin': 'Admin', 'action': 'user.suspend', 'target': 'User · Prasert Boonmee', 'details': 'Fake listings'},
        {'time': '7 Nov 2026 10:31', 'admin': 'Admin', 'action': 'report.keep', 'target': 'Review #29 · BIG BUNK', 'details': 'Report closed — review kept'},
        {'time': '6 Nov 2026 16:12', 'admin': 'Admin', 'action': 'dormitory.restore', 'target': 'Dorm · ดอยคำ เรสซิเดนซ์', 'details': 'Back to Published'},
        {'time': '6 Nov 2026 09:47', 'admin': 'Admin', 'action': 'owner.reject', 'target': 'User · Narin Thongdee', 'details': 'Document is blurry'},
      ];
      
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activity log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text('Sun 8 Nov 2026', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          )
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilters(),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    _buildTableHeader(),
                    ..._items.map((item) => _buildTableRow(item)).toList(),
                  ],
                ),
              ),
              _buildPagination(),
            ],
          ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildDropdown('All actions'),
              const SizedBox(width: 8),
              _buildDropdown('Last 7 days'),
            ],
          ),
          Text('Read-only · from admin_logs', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
          Expanded(flex: 1, child: Text('ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
          Expanded(flex: 2, child: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
          Expanded(flex: 3, child: Text('TARGET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
          Expanded(flex: 3, child: Text('DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item['time'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: Text(item['admin'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildActionBadge(item['action'].toString()))),
          Expanded(flex: 3, child: Text(item['target'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
          Expanded(flex: 3, child: Text(item['details'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        ],
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    Color bgColor, textColor;
    
    if (action.contains('approve') || action.contains('restore') || action.contains('keep')) {
      bgColor = const Color(0xFFE8F5E9); 
      textColor = const Color(0xFF2E7D32);
    } else if (action.contains('reject') || action.contains('hide')) {
      bgColor = const Color(0xFFFFEBEE); 
      textColor = const Color(0xFFC62828);
    } else if (action.contains('suspend')) {
      bgColor = const Color(0xFFFFF8E1); 
      textColor = const Color(0xFFF57F17);
    } else {
      bgColor = const Color(0xFFE3F2FD); 
      textColor = const Color(0xFF1565C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(action, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text('Showing 1–20 of 64', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }
}