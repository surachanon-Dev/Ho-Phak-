import 'package:flutter/material.dart';

class AdminDormsScreen extends StatefulWidget {
  const AdminDormsScreen({super.key});

  @override
  State<AdminDormsScreen> createState() => _AdminDormsScreenState();
}

class _AdminDormsScreenState extends State<AdminDormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // อัปเดต UI เมื่อเปลี่ยนแท็บ เพื่อเปลี่ยนปุ่ม/ช่องค้นหาด้านขวา
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.apartment, color: Colors.blue, size: 30),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ho-Phak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Admin dashboard', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildMenuItem(Icons.dashboard_outlined, 'Dashboard', null),
          _buildMenuItem(Icons.person_add_outlined, 'Owner requests', '3'),
          _buildMenuItem(Icons.domain, 'Dorms', '5', isSelected: true),
          _buildMenuItem(Icons.people_outline, 'Users', null),
          _buildMenuItem(Icons.star_outline, 'Reviews', '2'),
          _buildMenuItem(Icons.history, 'Activity log', null),
          _buildMenuItem(Icons.local_laundry_service_outlined, 'Amenities', null),
          _buildMenuItem(Icons.settings_outlined, 'Settings', null),
          const Spacer(),
          const Divider(),
          const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 12))),
            title: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Administrator', style: TextStyle(fontSize: 12)),
            trailing: Icon(Icons.logout, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String? badgeCount, {bool isSelected = false}) {
    return Container(
      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: badgeCount != null
            ? CircleAvatar(
                radius: 10,
                backgroundColor: Colors.blue,
                child: Text(badgeCount, style: const TextStyle(color: Colors.white, fontSize: 10)),
              )
            : null,
        onTap: () {},
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dorms', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Sun 8 Nov 2026', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Awaiting review  5'),
                  Tab(text: 'All dorms  48'),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search dorm or owner...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  if (_tabController.index == 1) ...[
                    const SizedBox(width: 10),
                    _buildDropdown('All statuses'),
                    const SizedBox(width: 10),
                    _buildDropdown('All zones'),
                  ]
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AwaitingReviewTab(),
                  AllDormsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          items: const [],
          onChanged: (value) {},
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: Awaiting Review
// ==========================================
class AwaitingReviewTab extends StatelessWidget {
  const AwaitingReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingTextStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                columnSpacing: 40,
                horizontalMargin: 24,
                columns: const [
                  DataColumn(label: Text('DORM')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('ZONE')),
                  DataColumn(label: Text('SUBMITTED')),
                  DataColumn(label: Text('CHANGED FIELDS')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  _buildRow('หอพักบ้านสวนดอย', 'Somchai Jaidee', 'New dorm', 'คชพลแลนด์', 'Today 07:58', '—', false),
                  _buildRow('เรือนแก้ว เพลส', 'Pimchanok Wongsa', 'New dorm', 'หน้ามอ', 'Yesterday 15:20', '—', false),
                  _buildRow('ลานนา ดอร์ม', 'Kanya Srisuk', 'New dorm', 'หลังมอ', '6 Nov 2026', '—', false),
                  _buildRow('หอพักริมดอย', 'Somchai Jaidee', 'Changes', 'หน้ามอ', '7 Nov 2026', 'Name, photos', true),
                  _buildRow('สุขใจ อพาร์ทเม้นท์', 'Kanya Srisuk', 'Changes', 'หลังมอ', '5 Nov 2026', 'Location', true),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Oldest first. Changes to price, rooms and utilities go live immediately and never appear here (D-61).',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(String dorm, String owner, String type, String zone, String submitted, String changed, bool isChanges) {
    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dorm, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(owner, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isChanges ? Colors.orange[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isChanges ? Colors.orange[200]! : Colors.blue[200]!),
            ),
            child: Text(
              type,
              style: TextStyle(color: isChanges ? Colors.orange[800] : Colors.blue[800], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(Text(zone)),
        DataCell(Text(submitted)),
        DataCell(Text(changed)),
        DataCell(
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: const BorderSide(color: Colors.grey)),
            child: const Text('Review'),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TAB 2: All Dorms
// ==========================================
class AllDormsTab extends StatelessWidget {
  const AllDormsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingTextStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                columnSpacing: 40,
                horizontalMargin: 24,
                columns: const [
                  DataColumn(label: Text('DORM')),
                  DataColumn(label: Text('ZONE')),
                  DataColumn(label: Text('PRICE / MONTH')),
                  DataColumn(label: Text('ROOMS')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  _buildAllDormsRow('หอพักริมดอย', 'Somchai Jaidee', 'หน้ามอ', '3,200 THB', '6 / 24 free', 'Changes pending'),
                  _buildAllDormsRow('หอพักลานหลวง', 'Somchai Jaidee', 'คชพลแลนด์', '2,900 THB', '2 / 22 free', 'Suspended'),
                  _buildAllDormsRow('BIG BUNK', 'Wichai Phrom', 'คชพลแลนด์', '3,000 THB', '20 / 50 free', 'Published'),
                  _buildAllDormsRow('เรือนแก้ว เพลส', 'Pimchanok Wongsa', 'หน้ามอ', '4,500 THB', '10 / 10 free', 'Pending review'),
                  _buildAllDormsRow('บ้านปลายฟ้า', 'Somchai Jaidee', 'หลังมอ', '2,500 THB', '0 / 16 free', 'Hidden'),
                  _buildAllDormsRow('ลานนา ดอร์ม', 'Kanya Srisuk', 'หลังมอ', '3,800 THB', '8 / 30 free', 'Pending review'),
                  _buildAllDormsRow('The Nest MFU', 'Wichai Phrom', 'หน้ามอ', '5,200 THB', '3 / 40 free', 'Published'),
                  _buildAllDormsRow('บ้านดอยคำ', 'Kanya Srisuk', 'คชพลแลนด์', '2,700 THB', '5 / 12 free', 'Rejected'),
                  _buildAllDormsRow('สุขใจ อพาร์ทเม้นท์', 'Kanya Srisuk', 'หลังมอ', '3,100 THB', '4 / 18 free', 'Changes pending'),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              Text('Showing 1-20 of 48', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildAllDormsRow(String dorm, String owner, String zone, String price, String rooms, String status) {
    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dorm, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(owner, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )),
        DataCell(Text(zone)),
        DataCell(Text(price)),
        DataCell(Text(rooms)),
        DataCell(_buildStatusBadge(status)),
        DataCell(
          TextButton(
            onPressed: () {},
            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Changes pending':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[800]!;
        break;
      case 'Suspended':
      case 'Rejected':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        break;
      case 'Published':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        break;
      case 'Pending review':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        break;
      case 'Hidden':
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}