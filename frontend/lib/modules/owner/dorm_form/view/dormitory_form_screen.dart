import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../../model/dormitory.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/app_services.dart';
import '../../validation/dormitory_rules.dart';
import '../controller/owner_dorm_form_controller.dart';

import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';
import '../../location_picker/view/location_picker_screen.dart';
import '../../../../widgets/ui/ui.dart';
import '../../../../model/dorm_utilities.dart';
import '../../../../model/dorm_document.dart';

/// ฟอร์มเพิ่ม/แก้ไขหอพัก
/// ทุกการบันทึกจะเข้าสถานะรอแอดมินตรวจสอบก่อน นักศึกษาจึงจะเห็น
class DormitoryFormScreen extends StatefulWidget {
  const DormitoryFormScreen({super.key, required this.services, this.existing});

  final AppServices services;

  /// null = เพิ่มใหม่, ไม่ null = แก้ไข (ต้องเป็นข้อมูลจาก GET รายละเอียด)
  final Dormitory? existing;

  @override
  State<DormitoryFormScreen> createState() => _DormitoryFormScreenState();
}

class _DormitoryFormScreenState extends State<DormitoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final OwnerDormFormController _c;
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _price;
  late final TextEditingController _totalRooms;
  late final TextEditingController _availableRooms;
  late final TextEditingController _waterRate;
  late final TextEditingController _electricityRate;
  late final TextEditingController _description;
  late final TextEditingController _contactPhone;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _c = OwnerDormFormController(
      existing: widget.existing,
      dorms: widget.services.dormitories,
    );
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    final d = widget.existing;
    _name = _sync(TextEditingController(text: d?.name ?? ''), _c.setName);
    _address = _sync(
      TextEditingController(text: d?.address ?? ''),
      _c.setAddress,
    );
    _price = _sync(
      TextEditingController(text: d?.pricePerMonth.toString() ?? ''),
      _c.setPrice,
    );
    _totalRooms = _sync(
      TextEditingController(text: d?.totalRooms.toString() ?? ''),
      _c.setTotalRooms,
    );
    _availableRooms = _sync(
      TextEditingController(text: d?.availableRooms.toString() ?? ''),
      _c.setAvailableRooms,
    );
    _waterRate = _sync(
      TextEditingController(text: _fmt(d?.waterRate)),
      _c.setWaterRate,
    );
    _electricityRate = _sync(
      TextEditingController(text: _fmt(d?.electricityRate)),
      _c.setElectricityRate,
    );
    _description = _sync(
      TextEditingController(text: d?.description ?? ''),
      _c.setDescription,
    );
    _contactPhone = _sync(
      TextEditingController(text: d?.contactPhone ?? ''),
      _c.setContactPhone,
    );
    _lat = _sync(
      TextEditingController(text: d?.latitude.toString() ?? ''),
      (v) {},
    );
    _lng = _sync(
      TextEditingController(text: d?.longitude.toString() ?? ''),
      (v) {},
    );
    _c.loadExtras();
  }

  /// ผูก TextEditingController กับค่าในตัว controller (ค่าที่กรอกถูกส่งไปที่ controller ทุกครั้งที่เปลี่ยน)
  TextEditingController _sync(
    TextEditingController c,
    void Function(String) push,
  ) {
    c.addListener(() => push(c.text));
    return c;
  }

  static String _fmt(double? v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    _c.dispose();
    for (final c in [
      _name,
      _address,
      _price,
      _totalRooms,
      _availableRooms,
      _waterRate,
      _electricityRate,
      _description,
      _contactPhone,
      _lat,
      _lng,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _c.pending.isEmpty) {
      _snack('Add at least 1 photo');
      return;
    }
    final result = await _c.save();
    if (!mounted) return;
    if (result == null) {
      if (_c.error != null) showApiError(context, widget.services, _c.error!);
      return;
    }
    if (result.photoError != null) _snack(result.photoError!);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const IconBadge(
          icon: Icons.mark_email_read_outlined,
          tone: Tone.success,
          size: 48,
        ),
        title: const Text('Sent for review', textAlign: TextAlign.center),
        content: Text(
          'Admin will review ${_name.text.trim()} (usually 1–2 days). '
          'Students will see it after approval.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _gap() => const SizedBox(height: 12);

  /// ป้ายชื่อช่องอยู่เหนือช่องกรอก (ตาม Figma) ดอกจัน * เป็นสีแดง
  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textBody,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
        ],
      ),
    ),
  );

  Widget _labeled(String text, Widget field, {bool required = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(text, required: required),
      field,
    ],
  );

  /// ส่วนรูปหอพัก: ดูรูปเดิม ลบทีละรูป และเพิ่มได้สูงสุด 10 รูปต่อหอ
  Widget _imagesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_c.images.length} of 10 photos',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final img in _c.images)
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(
                        img.fullUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    if (img == _c.images.first)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: _c.busyImages ? null : () => _deleteImage(img),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_c.images.length < 10)
              _addPhotoTile(_c.busyImages ? null : _pickAndUploadImages),
          ],
        ),
        if (_c.busyImages) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  /// ส่วนรูปตอน Add: เลือกไว้ก่อน แล้วอัปโหลดหลังบันทึกหอ
  Widget _pendingSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _c.pending.length; i++)
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.memory(_c.pending[i].bytes, fit: BoxFit.cover),
                ),
                if (i == 0)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: () => _c.removePending(i),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_c.pending.length < DormitoryRules.maxImages)
          _addPhotoTile(_pickPending),
      ],
    );
  }

  Future<void> _pickPending() async {
    final picked = await ImagePicker().pickMultiImage(
      limit: _c.pickLimit,
      imageQuality: 90,
    );
    if (picked.isEmpty) return;
    final added = <UploadFile>[];
    for (final p in picked) {
      final Uint8List bytes = await p.readAsBytes();
      if (bytes.length > DormitoryRules.maxImageBytes) {
        _snack('${p.name} is larger than 5 MB');
        return;
      }
      added.add(UploadFile(bytes: bytes, filename: p.name));
    }
    _c.addPending(added);
  }

  /// เลือกรูป (สูงสุด 5 รูปต่อครั้ง ไม่เกิน 10 รูปต่อหอ) แล้วอัปโหลด
  Future<void> _pickAndUploadImages() async {
    final picked = await ImagePicker().pickMultiImage(
      limit: _c.pickLimit,
      imageQuality: 90,
    );
    if (picked.isEmpty) return;
    final files = <UploadFile>[];
    for (final p in picked) {
      final bytes = await p.readAsBytes();
      if (bytes.length > DormitoryRules.maxImageBytes) {
        _snack('${p.name} is larger than 5 MB');
        return;
      }
      files.add(UploadFile(bytes: bytes, filename: p.name));
    }
    final ok = await _c.uploadImages(files);
    if (!mounted) return;
    if (ok) {
      _snack('Photos uploaded');
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _deleteImage(DormImage img) async {
    final ok = await _c.deleteImage(img);
    if (!mounted) return;
    if (!ok && _c.error != null)
      showApiError(context, widget.services, _c.error!);
  }

  void _snack(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));

  /// เปิดหน้าปักหมุด แล้วเอาพิกัดที่เลือกไปใส่ในช่อง lat/lng
  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _c.currentLocation),
      ),
    );
    if (picked == null || !mounted) return;
    _c.setLocation(picked);
    _lat.text = _c.latitude;
    _lng.text = _c.longitude;
  }

  bool get _hasLocation => _c.hasLocation;

  static const _sectionIcons = {
    'Basic info': Icons.info_outline_rounded,
    'Location': Icons.place_outlined,
    'Photos': Icons.photo_library_outlined,
    'Price & rooms': Icons.payments_outlined,
    'Water & electricity': Icons.bolt_outlined,
    'Amenities': Icons.sell_outlined,
    'Contact': Icons.phone_outlined,
    'Ownership document': Icons.verified_outlined,
  };

  Widget _card(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: _sectionIcons[title] ?? Icons.circle_outlined,
                size: 34,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  /// ปุ่มเพิ่มรูปแบบกล่องเส้นประ ขนาดเท่ารูป
  Widget _addPhotoTile(VoidCallback? onTap) => SizedBox(
    width: 96,
    height: 96,
    child: Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFC7CCF5), width: 1.4),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
              ),
              SizedBox(height: 4),
              Text(
                'Add photo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _pickDocument() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: DormitoryRules.documentExtensions,
    );
    if (f == null) return;
    final size = await f.length() ?? 0;
    if (size > DormitoryRules.maxDocumentBytes) {
      _snack('File is larger than 10 MB');
      return;
    }
    final bytes = await f.readAsBytes();
    _c.setDocument(
      DormDocument(name: f.name, sizeBytes: bytes.length, bytes: bytes),
    );
  }

  /// ตัวเลือก Set price / Included / Not specified + ช่องอัตราเมื่อเลือก Set price
  Widget _utilityBlock({
    required UtilityMode mode,
    required ValueChanged<UtilityMode> onMode,
    required TextEditingController rate,
    required String? type,
    required ValueChanged<String?> onType,
    required String rateLabel,
  }) {
    const labels = {
      UtilityMode.setPrice: 'Set price',
      UtilityMode.included: 'Included',
      UtilityMode.notSpecified: 'Not specified',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in UtilityMode.values)
              ChoiceChip(
                label: Text(labels[m]!),
                selected: mode == m,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: mode == m ? Colors.white : AppColors.textBody,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onMode(m),
              ),
          ],
        ),
        if (mode == UtilityMode.setPrice) ...[
          const SizedBox(height: 12),
          _utilityFields(
            rate: rate,
            type: type,
            onType: onType,
            rateLabel: rateLabel,
          ),
        ],
      ],
    );
  }

  /// ช่องอัตราค่าน้ำ/ไฟ + วิธีคิด (API เก็บเฉพาะอัตรากับวิธีคิด)
  Widget _utilityFields({
    required TextEditingController rate,
    required String? type,
    required ValueChanged<String?> onType,
    required String rateLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _labeled(
            rateLabel,
            TextFormField(
              controller: rate,
              decoration: const InputDecoration(suffixText: 'THB'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: DormitoryRules.rateRequired,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _labeled(
            'Billed',
            DropdownButtonFormField<String>(
              initialValue: type,
              isExpanded: true,
              hint: const Text('Choose'),
              decoration: const InputDecoration(),
              items: BillingType.all
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        BillingType.labelEn(t),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              validator: (v) => DormitoryRules.billing(v, rate.text),
              onChanged: onType,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit dorm' : 'Add dorm'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _c.saving,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ลำดับกล่องตาม Figma (D-175):
                          // Basic info → Location (+ Address) → Photos →
                          // Price & rooms → Water & electricity → Contact
                          _card('Basic info', [
                            _labeled(
                              'Dorm name',
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Baan Suan Dorm',
                                ),
                                validator: DormitoryRules.required,
                              ),
                              required: true,
                            ),
                            _gap(),
                            _label('Zone', required: true),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final z in dormZones)
                                  ChoiceChip(
                                    label: Text(zoneLabel(z)),
                                    selected: _c.zone == z,
                                    showCheckmark: false,
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: _c.zone == z
                                          ? Colors.white
                                          : AppColors.textBody,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (_) => _c.setZone(z),
                                  ),
                              ],
                            ),
                            _gap(),
                            _labeled(
                              'Description',
                              TextFormField(
                                controller: _description,
                                decoration: const InputDecoration(
                                  hintText: 'Tell students about your dorm',
                                ),
                                maxLines: 4,
                              ),
                            ),
                          ]),
                          _card('Location', [
                            FormField<bool>(
                              initialValue: _hasLocation,
                              validator: (_) => _hasLocation
                                  ? null
                                  : 'Pin the dorm location on the map',
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      6,
                                      6,
                                      6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _hasLocation
                                          ? AppColors.successSoft
                                          : AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      border: Border.all(
                                        color: field.hasError
                                            ? AppColors.danger
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: _hasLocation
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _hasLocation
                                                ? '${_lat.text.trim()}, ${_lng.text.trim()}'
                                                : 'No location set',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await _pickLocation();
                                            field.didChange(_hasLocation);
                                          },
                                          child: Text(
                                            _hasLocation
                                                ? 'Change'
                                                : 'Pin on map',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (field.hasError) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      field.errorText!,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            _gap(),
                            _labeled(
                              'Address',
                              TextFormField(
                                controller: _address,
                                decoration: const InputDecoration(
                                  hintText: 'House no., street, sub-district',
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ]),
                          _card('Photos', [
                            if (_isEdit)
                              _imagesSection()
                            else
                              _pendingSection(),
                            const SizedBox(height: 8),
                            const Text(
                              'At least 1 photo. The first photo is the cover.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ]),
                          _card('Price & rooms', [
                            _labeled(
                              'Monthly price',
                              TextFormField(
                                controller: _price,
                                decoration: const InputDecoration(
                                  suffixText: 'THB',
                                ),
                                keyboardType: TextInputType.number,
                                validator: DormitoryRules.price,
                              ),
                              required: true,
                            ),
                            _gap(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _labeled(
                                    'Total rooms',
                                    TextFormField(
                                      controller: _totalRooms,
                                      keyboardType: TextInputType.number,
                                      validator: DormitoryRules.totalRooms,
                                    ),
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _labeled(
                                    'Available now',
                                    TextFormField(
                                      controller: _availableRooms,
                                      keyboardType: TextInputType.number,
                                      validator: (v) =>
                                          DormitoryRules.availableRooms(
                                            v,
                                            _totalRooms.text,
                                          ),
                                    ),
                                    required: true,
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          _card('Water & electricity', [
                            _label('Water'),
                            _utilityBlock(
                              mode: _c.waterMode,
                              onMode: _c.setWaterMode,
                              rate: _waterRate,
                              type: _c.waterType,
                              onType: _c.setWaterType,
                              rateLabel: 'Water rate',
                            ),
                            _gap(),
                            _label('Electricity'),
                            _utilityBlock(
                              mode: _c.electricityMode,
                              onMode: (m) => _c.setElectricityMode(m),
                              rate: _electricityRate,
                              type: _c.electricityType,
                              onType: (v) => _c.setElectricityType(v),
                              rateLabel: 'Electricity rate',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rates apply only when "Set price" is selected. '
                              '"Included" = already in the rent.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ]),
                          _card('Amenities', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final a in _c.catalog)
                                  FilterChip(
                                    label: Text(a.name),
                                    selected: _c.amenityIds.contains(a.id),
                                    showCheckmark: true,
                                    selectedColor: AppColors.primarySoft,
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _c.amenityIds.contains(a.id)
                                          ? AppColors.primary
                                          : AppColors.textBody,
                                    ),
                                    onSelected: (on) => _c.toggleAmenity(a.id),
                                  ),
                              ],
                            ),
                          ]),
                          _card('Contact', [
                            _labeled(
                              'Contact phone',
                              TextFormField(
                                controller: _contactPhone,
                                keyboardType: TextInputType.phone,
                                validator: (_) => _c.validateContactPhone(),
                                decoration: const InputDecoration(
                                  hintText: '08X-XXX-XXXX',
                                ),
                              ),
                            ),
                          ]),
                          _card('Ownership document', [
                            if (_c.document != null)
                              Container(
                                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _c.document!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            _c.document!.sizeBytes > 0
                                                ? '${(_c.document!.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                                                : 'Uploaded document',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _pickDocument,
                                      child: const Text('Change'),
                                    ),
                                  ],
                                ),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _pickDocument,
                                icon: const Icon(Icons.upload_file_outlined),
                                label: const Text('Upload document'),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              '1 document proving you own this dorm (title '
                              'deed, lease or business licence). Each dorm '
                              'needs its own document.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Admin reviews every save before students can see it (usually 1–2 days).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _c.saving ? null : _save,
                          child: _c.saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit for review'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
