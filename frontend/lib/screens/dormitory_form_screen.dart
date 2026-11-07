import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../services/app_services.dart';

import 'package:latlong2/latlong.dart';

import '../ui/error_handling.dart';
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
          title: const Text('ส่งให้ตรวจสอบแล้ว'),
          content: Text(
            'แอดมินจะตรวจสอบ ${_name.text.trim()} มักใช้เวลา 1–2 วัน '
            'นักศึกษาจะเห็นหลังได้รับการอนุมัติ',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ตกลง'),
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
      (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูลนี้' : null;

  String? _priceValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'ต้องเป็นจำนวนเต็ม';
    if (n < 1 || n > 1000000) return 'ราคาต้องอยู่ระหว่าง 1 ถึง 1,000,000 บาท';
    return null;
  }

  String? _totalValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'ต้องเป็นจำนวนเต็ม';
    return n < 0 ? 'จำนวนห้องต้องไม่ติดลบ' : null;
  }

  String? _availableValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'ต้องเป็นจำนวนเต็ม';
    final total = int.tryParse(_totalRooms.text.trim());
    if (n < 0) return 'ห้องว่างต้องไม่ติดลบ';
    if (total != null && n > total) return 'ห้องว่างต้องไม่เกินห้องทั้งหมด';
    return null;
  }

  String? _rateValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null) return 'ต้องเป็นตัวเลข';
    return n < 0 ? 'ต้องไม่ติดลบ' : null;
  }

  String? _billingValidator(String? v, String rateText) {
    if (rateText.trim().isNotEmpty && v == null) {
      return 'เลือกรูปแบบการคิดเงิน';
    }
    return null;
  }

  String? _latValidator(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'ต้องเป็นตัวเลข';
    return (n < -90 || n > 90) ? 'lat ต้องอยู่ระหว่าง -90 ถึง 90' : null;
  }

  String? _lngValidator(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'ต้องเป็นตัวเลข';
    return (n < -180 || n > 180) ? 'lng ต้องอยู่ระหว่าง -180 ถึง 180' : null;
  }

  Widget _gap() => const SizedBox(height: 12);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขหอพัก' : 'เพิ่มหอพัก')),
      body: AbsorbPointer(
        absorbing: _saving,
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
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'ชื่อหอพัก'),
                      validator: _required,
                    ),
                    _gap(),
                    DropdownButtonFormField<String>(
                      initialValue: _zone,
                      decoration: const InputDecoration(labelText: 'โซน'),
                      items: dormZones
                          .map(
                            (z) => DropdownMenuItem(value: z, child: Text(z)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _zone = v ?? _zone),
                    ),
                    _gap(),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'ที่อยู่'),
                      maxLines: 2,
                    ),
                    _gap(),
                    TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(
                        labelText: 'ราคา/เดือน (บาท)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _priceValidator,
                    ),
                    _gap(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalRooms,
                            decoration: const InputDecoration(
                              labelText: 'ห้องทั้งหมด',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _totalValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _availableRooms,
                            decoration: const InputDecoration(
                              labelText: 'ห้องว่างตอนนี้',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _availableValidator,
                          ),
                        ),
                      ],
                    ),
                    _gap(),
                    Text(
                      'ค่าน้ำ (ไม่บังคับ)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _waterRate,
                            decoration: const InputDecoration(
                              labelText: 'อัตรา (บาท)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _rateValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _waterType,
                            decoration: const InputDecoration(
                              labelText: 'คิดแบบ',
                            ),
                            items: BillingType.all
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(BillingType.label(t)),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                _billingValidator(v, _waterRate.text),
                            onChanged: (v) => setState(() => _waterType = v),
                          ),
                        ),
                      ],
                    ),
                    _gap(),
                    Text(
                      'ค่าไฟ (ไม่บังคับ)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _electricityRate,
                            decoration: const InputDecoration(
                              labelText: 'อัตรา (บาท)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _rateValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _electricityType,
                            decoration: const InputDecoration(
                              labelText: 'คิดแบบ',
                            ),
                            items: BillingType.all
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(BillingType.label(t)),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                _billingValidator(v, _electricityRate.text),
                            onChanged: (v) =>
                                setState(() => _electricityType = v),
                          ),
                        ),
                      ],
                    ),
                    _gap(),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียด',
                      ),
                      maxLines: 4,
                    ),
                    _gap(),
                    TextFormField(
                      controller: _contactPhone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์ติดต่อ (ไม่บังคับ)',
                      ),
                    ),
                    _gap(),
                    OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('ปักหมุดบนแผนที่'),
                    ),
                    _gap(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lat,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: _latValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lng,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: _lngValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ส่งให้แอดมินตรวจสอบ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
