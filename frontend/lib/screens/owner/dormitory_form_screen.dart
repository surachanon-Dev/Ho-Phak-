import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/dormitory.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import 'location_picker_screen.dart';

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

  late String _zone;
  String? _waterType;
  String? _electricityType;
  bool _saving = false;
  bool _busyImages = false;
  List<DormImage> _images = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _name = TextEditingController(text: d?.name ?? '');
    _address = TextEditingController(text: d?.address ?? '');
    _price = TextEditingController(text: d?.pricePerMonth.toString() ?? '');
    _totalRooms = TextEditingController(text: d?.totalRooms.toString() ?? '');
    _availableRooms = TextEditingController(
      text: d?.availableRooms.toString() ?? '',
    );
    _waterRate = TextEditingController(text: _fmt(d?.waterRate));
    _electricityRate = TextEditingController(text: _fmt(d?.electricityRate));
    _description = TextEditingController(text: d?.description ?? '');
    _contactPhone = TextEditingController(text: d?.contactPhone ?? '');
    _lat = TextEditingController(text: d?.latitude.toString() ?? '');
    _lng = TextEditingController(text: d?.longitude.toString() ?? '');
    _zone = d?.zone ?? dormZones.first;
    _images = List.of(d?.images ?? const []);
    _waterType = d?.waterBillingType;
    _electricityType = d?.electricityBillingType;
  }

  static String _fmt(double? v) => v == null ? '' : v.toString();

  @override
  void dispose() {
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

  String? _optional(String text) {
    final t = text.trim();
    return t.isEmpty ? null : t;
  }

  double? _parseRate(String text) {
    final t = text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  DormitoryInput _buildInput() {
    final waterRate = _parseRate(_waterRate.text);
    final electricityRate = _parseRate(_electricityRate.text);
    return DormitoryInput(
      name: _name.text.trim(),
      zone: _zone,
      latitude: double.parse(_lat.text.trim()),
      longitude: double.parse(_lng.text.trim()),
      pricePerMonth: int.parse(_price.text.trim()),
      totalRooms: int.parse(_totalRooms.text.trim()),
      availableRooms: int.parse(_availableRooms.text.trim()),
      // rate กับ billing type ต้องคู่กัน จึงส่งเฉพาะเมื่อกรอกอัตรา
      waterRate: waterRate,
      waterBillingType: waterRate == null ? null : _waterType,
      electricityRate: electricityRate,
      electricityBillingType: electricityRate == null ? null : _electricityType,
      address: _optional(_address.text),
      description: _optional(_description.text),
      contactPhone: _optional(_contactPhone.text),
      // ยังไม่มี UI เลือกสิ่งอำนวยความสะดวก (รอทีมยืนยัน endpoint)
      // จึงส่งค่าเดิมกลับไปเพื่อไม่ให้ PUT ลบรายการเดิม
      amenityIds: widget.existing?.amenityIds ?? const [],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final input = _buildInput();
      if (_isEdit) {
        await widget.services.dormitories.update(widget.existing!.id, input);
      } else {
        await widget.services.dormitories.create(input);
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sent for review'),
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
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _priceValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    if (n < 1 || n > 1000000) return 'Price must be between 1 and 1,000,000 THB';
    return null;
  }

  String? _totalValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    return n < 0 ? 'Rooms cannot be negative' : null;
  }

  String? _availableValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    final total = int.tryParse(_totalRooms.text.trim());
    if (n < 0) return 'Available rooms cannot be negative';
    if (total != null && n > total) return 'Available rooms cannot exceed total rooms';
    return null;
  }

  String? _rateValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null) return 'Enter a number';
    return n < 0 ? 'Cannot be negative' : null;
  }

  String? _billingValidator(String? v, String rateText) {
    if (rateText.trim().isNotEmpty && v == null) {
      return 'Choose how it is billed';
    }
    return null;
  }

  Widget _gap() => const SizedBox(height: 12);

  /// ป้ายชื่อช่องอยู่เหนือช่องกรอก (ตาม Figma) ดอกจัน * เป็นสีแดง
  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
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

  Widget _labeled(String text, Widget field, {bool required = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_label(text, required: required), field],
      );

  /// ส่วนรูปหอพัก: ดูรูปเดิม ลบทีละรูป และเพิ่มได้สูงสุด 10 รูปต่อหอ
  Widget _imagesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_images.length} of 10 photos',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final img in _images)
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img.fullUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    if (img == _images.first)
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
                        onTap: _busyImages ? null : () => _deleteImage(img),
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
            if (_images.length < 10)
              OutlinedButton.icon(
                onPressed: _busyImages ? null : _pickAndUploadImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photo'),
              ),
          ],
        ),
        if (_busyImages) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  /// เลือกรูป (สูงสุด 5 รูปต่อครั้ง ไม่เกิน 10 รูปต่อหอ) แล้วอัปโหลด
  Future<void> _pickAndUploadImages() async {
    final remaining = 10 - _images.length;
    final picked = await ImagePicker().pickMultiImage(
      limit: remaining > 5 ? 5 : remaining,
      imageQuality: 90,
    );
    if (picked.isEmpty) return;
    final files = <UploadFile>[];
    for (final p in picked) {
      final bytes = await p.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _snack('${p.name} is larger than 5 MB');
        return;
      }
      files.add(UploadFile(bytes: bytes, filename: p.name));
    }
    setState(() => _busyImages = true);
    try {
      await widget.services.dormitories.uploadImages(
        widget.existing!.id,
        files,
      );
      await _reloadImages();
      _snack('Photos uploaded');
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busyImages = false);
    }
  }

  Future<void> _deleteImage(DormImage img) async {
    setState(() => _busyImages = true);
    try {
      await widget.services.dormitories.deleteImage(
        widget.existing!.id,
        img.id,
      );
      await _reloadImages();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busyImages = false);
    }
  }

  /// โหลดรายการรูปใหม่จากรายละเอียดหอพัก
  Future<void> _reloadImages() async {
    final fresh = await widget.services.dormitories.get(widget.existing!.id);
    if (mounted) setState(() => _images = List.of(fresh.images));
  }

  void _snack(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));

  /// เปิดหน้าปักหมุด แล้วเอาพิกัดที่เลือกไปใส่ในช่อง lat/lng
  Future<void> _pickLocation() async {
    final current =
        double.tryParse(_lat.text.trim()) != null &&
            double.tryParse(_lng.text.trim()) != null
        ? LatLng(double.parse(_lat.text.trim()), double.parse(_lng.text.trim()))
        : null;
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: current)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _lat.text = picked.latitude.toStringAsFixed(6);
      _lng.text = picked.longitude.toStringAsFixed(6);
    });
  }

  bool get _hasLocation =>
      double.tryParse(_lat.text.trim()) != null &&
      double.tryParse(_lng.text.trim()) != null;

  Widget _card(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

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
              validator: _rateValidator,
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
              validator: (v) => _billingValidator(v, rate.text),
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
        absorbing: _saving,
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
                                  hintText: 'e.g. หอพักบ้านสวน',
                                ),
                                validator: _required,
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
                                    label: Text(z),
                                    selected: _zone == z,
                                    showCheckmark: false,
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: _zone == z
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (_) =>
                                        setState(() => _zone = z),
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
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: _hasLocation
                                            ? AppColors.danger
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _hasLocation
                                              ? '${_lat.text.trim()}, ${_lng.text.trim()}'
                                              : 'No location set',
                                          style: const TextStyle(fontSize: 14),
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
                                  if (field.hasError)
                                    Text(
                                      field.errorText!,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 12,
                                      ),
                                    ),
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
                              const Text(
                                'You can add photos right after the dorm is saved.',
                                style: TextStyle(
                                  fontSize: 13,
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
                                validator: _priceValidator,
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
                                      validator: _totalValidator,
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
                                      validator: _availableValidator,
                                    ),
                                    required: true,
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          _card('Water & electricity', [
                            _label('Water'),
                            _utilityFields(
                              rate: _waterRate,
                              type: _waterType,
                              onType: (v) => setState(() => _waterType = v),
                              rateLabel: 'Water rate',
                            ),
                            _gap(),
                            _label('Electricity'),
                            _utilityFields(
                              rate: _electricityRate,
                              type: _electricityType,
                              onType: (v) =>
                                  setState(() => _electricityType = v),
                              rateLabel: 'Electricity rate',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Leave the rate empty if it is not specified.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ]),
                          _card('Contact', [
                            _labeled(
                              'Contact phone',
                              TextFormField(
                                controller: _contactPhone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: '08X-XXX-XXXX',
                                ),
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
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
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit for review'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
