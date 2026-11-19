import 'package:flutter/material.dart';

import '../../../../app/session.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui/ui.dart';
import '../../owner_requests/view/widgets/reject_request_dialog.dart'
    show dangerButtonStyle, primaryElevatedStyle;
import '../../../../services/admin_service.dart';
import '../../widgets/admin_page.dart';
import '../controller/admin_amenities_controller.dart';

/// หน้า Amenities: รายการสิ่งอำนวยความสะดวก เพิ่ม/แก้ไข/ลบ
class AdminAmenitiesTab extends StatefulWidget {
  const AdminAmenitiesTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminAmenitiesTab> createState() => _AdminAmenitiesTabState();
}

class _AdminAmenitiesTabState extends State<AdminAmenitiesTab> {
  late final AdminAmenitiesController _ac;
  String _query = '';

  List<_AmenityItem> get _amenities =>
      _ac.items.map(_AmenityItem.fromAmenity).toList();

  @override
  void initState() {
    super.initState();
    _ac = AdminAmenitiesController(AdminService(widget.services.api));
    _ac.addListener(_onChanged);
    _ac.load().then((ok) {
      if (!ok && mounted && _ac.error != null) {
        showApiError(context, widget.services, _ac.error!);
      }
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ac.removeListener(_onChanged);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildAmenitiesView();

  Future<void> _showAddOrEditAmenityDialog({_AmenityItem? existing}) async {
    final isEdit = existing != null;
    final controller = TextEditingController(text: existing?.name ?? '');
    String? errorText;

    final savedName = await showDialog<String>(
      context: context,
      barrierColor: const Color(0x8C0F172A),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void submit() {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) {
                setDialogState(() {
                  errorText = 'Please enter an amenity name.';
                });
                return;
              }
              final duplicate = _amenities.any(
                (a) =>
                    a.id != existing?.id &&
                    a.name.toLowerCase() == trimmed.toLowerCase(),
              );
              if (duplicate) {
                setDialogState(() {
                  errorText = 'This amenity name already exists.';
                });
                return;
              }
              Navigator.of(ctx).pop(trimmed);
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        icon: isEdit ? Icons.edit_outlined : Icons.add_rounded,
                        size: 44,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isEdit ? 'Edit amenity' : 'Add amenity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        onChanged: (_) {
                          if (errorText != null) {
                            setDialogState(() => errorText = null);
                          }
                        },
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Air conditioner',
                          errorText: errorText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Names must be unique. Editing a name updates every dorm that uses it.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: submit,
                            style: primaryElevatedStyle(),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (savedName == null || !mounted) return;
    final ok = isEdit
        ? await _ac.rename(int.parse(existing.id), savedName)
        : await _ac.add(savedName);
    if (!mounted) return;
    if (!ok && _ac.error != null) {
      showApiError(context, widget.services, _ac.error!);
    }
  }

  Future<void> _showDeleteAmenityDialog(_AmenityItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x8C0F172A),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(
                    icon: Icons.delete_outline,
                    tone: Tone.danger,
                    size: 44,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Delete amenity?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${item.name}" will be removed from every dorm that uses it. This cannot be undone.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: dangerButtonStyle(),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      final ok = await _ac.delete(int.parse(item.id));
      if (!mounted) return;
      if (!ok && _ac.error != null) {
        showApiError(context, widget.services, _ac.error!);
      }
    }
  }

  Widget _buildAmenitiesView() {
    final all = _amenities;
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? all
        : all.where((a) => a.name.toLowerCase().contains(q)).toList();
    final pad = adminPagePadding(context);

    return AdminPage(
      title: 'Amenities',
      subtitle:
          'Owners pick from this list when they add or edit a dorm · ${all.length} items',
      actions: [
        FilledButton.icon(
          onPressed: () => _showAddOrEditAmenityDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add amenity'),
        ),
      ],
      toolbar: all.isEmpty
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SearchField(
                hint: 'Search amenities...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
      child: _ac.loading && all.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? EmptyState(
              icon: Icons.sell_outlined,
              tone: Tone.neutral,
              title: 'No amenities',
              message: q.isEmpty
                  ? 'Add the first amenity owners can choose from.'
                  : 'Nothing matches "$_query".',
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
              child: ContentWidth(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cols = (c.maxWidth / 260).floor().clamp(1, 4);
                    const gap = 12.0;
                    final w = (c.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: w,
                            child: _AmenityCard(
                              item: item,
                              onEdit: () =>
                                  _showAddOrEditAmenityDialog(existing: item),
                              onDelete: () => _showDeleteAmenityDialog(item),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  const _AmenityCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final _AmenityItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      child: Row(
        children: [
          IconBadge(icon: amenityIcon(item.name), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 19,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

/// เดาไอคอนจากชื่อสิ่งอำนวยความสะดวก (ทั้งไทยและอังกฤษ)
IconData amenityIcon(String name) {
  final n = name.toLowerCase();
  bool has(List<String> keys) => keys.any(n.contains);
  if (has(['wifi', 'wi-fi', 'internet', 'อินเทอร์เน็ต', 'ไวไฟ'])) {
    return Icons.wifi_rounded;
  }
  if (has(['air', 'แอร์', 'ปรับอากาศ'])) return Icons.ac_unit_rounded;
  if (has(['park', 'จอด'])) return Icons.local_parking_rounded;
  if (has(['laundry', 'wash', 'ซัก'])) {
    return Icons.local_laundry_service_outlined;
  }
  if (has(['cctv', 'camera', 'กล้อง'])) return Icons.videocam_outlined;
  if (has(['security', 'guard', 'รปภ', 'ยาม', 'key card', 'คีย์การ์ด'])) {
    return Icons.security_rounded;
  }
  if (has(['fridge', 'refrigerator', 'ตู้เย็น'])) return Icons.kitchen_outlined;
  if (has(['water heater', 'heater', 'น้ำอุ่น'])) {
    return Icons.hot_tub_outlined;
  }
  if (has(['tv', 'ทีวี', 'โทรทัศน์'])) return Icons.tv_rounded;
  if (has(['lift', 'elevator', 'ลิฟต์'])) return Icons.elevator_outlined;
  if (has(['gym', 'fitness', 'ฟิตเนส'])) return Icons.fitness_center_rounded;
  if (has(['pet', 'สัตว์'])) return Icons.pets_rounded;
  if (has(['bed', 'เตียง', 'furniture', 'เฟอร์'])) return Icons.bed_outlined;
  if (has(['shop', 'store', 'ร้าน'])) return Icons.storefront_outlined;
  return Icons.check_circle_outline_rounded;
}

class _AmenityItem {
  /// แปลงจาก AdminAmenity ของ backend
  factory _AmenityItem.fromAmenity(AdminAmenity a) =>
      _AmenityItem(id: '${a.id}', name: a.name);

  const _AmenityItem({required this.id, required this.name});

  final String id;
  final String name;
}
