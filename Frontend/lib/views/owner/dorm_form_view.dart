import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../controllers/owner_controller.dart';
import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import '../../services/dorm_service.dart';
import '../../services/owner_service.dart';
import '../widgets/common.dart';
import 'location_picker_view.dart';

/// Add / edit a dorm. Field names follow the `dormitories` table.
/// - new dorm → must attach photos + ownership document → status pending (admin approves)
/// - edit → saved right away (rejected → back to pending for review)
/// - suspended → read-only
class DormFormView extends StatefulWidget {
  const DormFormView({super.key, this.dormId});
  final int? dormId;

  @override
  State<DormFormView> createState() => _DormFormViewState();
}

class _DormFormViewState extends State<DormFormView> {
  final _formKey = GlobalKey<FormState>();
  DormForm _f = DormForm();
  Dormitory? _dorm;
  List<Amenity> _amenities = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  // text controllers
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _water = TextEditingController();
  final _elec = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();

  bool get _isEdit => widget.dormId != null;
  bool get _readOnly => _dorm?.status == 'suspended';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _water, _elec, _desc, _address, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _amenities = await context.read<DormService>().amenities();
      if (_isEdit) {
        if (!mounted) return;
        _dorm = await context.read<OwnerController>().service.get(widget.dormId!);
        _f = DormForm.fromDorm(_dorm!);
        _name.text = _f.name;
        _price.text = '${_f.pricePerMonth ?? ''}';
        _water.text = _f.waterRate?.toString() ?? '';
        _elec.text = _f.electricityRate?.toString() ?? '';
        _desc.text = _f.description;
        _address.text = _f.address;
        _phone.text = _f.contactPhone;
      }
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (files.isEmpty) return;
    setState(() => _f.images.addAll(files.map((x) => x.path)));
  }

  Future<void> _pickDocImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _f.ownershipDocument = x.path);
  }

  Future<void> _pickDocFile() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    final f = r?.files.single;
    if (f == null) return;
    // on web there is no real path – keep the name (the real app will upload the bytes)
    setState(() => _f.ownershipDocument = kIsWeb || f.path == null ? 'uploads/documents/${f.name}' : f.path);
  }

  bool _isImagePath(String p) {
    final l = p.toLowerCase();
    return !l.endsWith('.pdf') && !l.startsWith('uploads/documents/');
  }

  Future<void> _pickLocation() async {
    final initial = _f.latitude == null ? null : LatLng(_f.latitude!, _f.longitude!);
    final p = await Navigator.push<LatLng>(context, MaterialPageRoute(builder: (_) => LocationPickerView(initial: initial)));
    if (p == null) return;
    setState(() {
      _f.latitude = p.latitude;
      _f.longitude = p.longitude;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_f.latitude == null) return showSnack(context, 'กรุณาปักหมุดตำแหน่งหอพักบนแผนที่', error: true);
    if (_f.images.isEmpty) return showSnack(context, 'กรุณาแนบรูปหอพักอย่างน้อย 1 รูป', error: true);
    if ((_f.ownershipDocument ?? '').isEmpty) return showSnack(context, 'กรุณาแนบเอกสารแสดงความเป็นเจ้าของหอพัก', error: true);
    _f
      ..name = _name.text
      ..pricePerMonth = int.tryParse(_price.text)
      ..waterRate = num.tryParse(_water.text)
      ..electricityRate = num.tryParse(_elec.text)
      ..description = _desc.text
      ..address = _address.text
      ..contactPhone = _phone.text;

    setState(() => _busy = true);
    final service = context.read<OwnerController>().service;
    try {
      String msg;
      if (_isEdit) {
        msg = await service.update(widget.dormId!, _f);
      } else {
        await service.create(_f);
        msg = 'เพิ่มหอพักแล้ว – รอผู้ดูแลระบบตรวจสอบ';
      }
      if (!mounted) return;
      showSnack(context, msg);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- validators ----------
  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'จำเป็นต้องกรอก' : null;

  String? _intMin(String? v, int min) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'กรอกเป็นตัวเลข';
    if (n < min) return 'ต้องไม่น้อยกว่า $min';
    return null;
  }

  String? _optionalNum(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = num.tryParse(v!.trim());
    return n == null || n < 0 ? 'กรอกตัวเลขที่ไม่ติดลบ' : null;
  }

  Widget? _statusNotice() {
    final d = _dorm;
    if (d == null) {
      return const NoticeCard(
          text: 'แนบรูปหอพักและเอกสารแสดงความเป็นเจ้าของ (เช่น โฉนด สัญญาเช่า ใบอนุญาตประกอบกิจการ)\n'
              'หอพักใหม่จะอยู่ในสถานะ "รอตรวจสอบ" จนกว่าผู้ดูแลระบบจะอนุมัติ');
    }
    return switch (d.status) {
      'rejected' => NoticeCard(
          color: AppColors.danger,
          title: 'ไม่อนุมัติ',
          text: 'เหตุผล: ${d.rejectionReason ?? '-'}\nแก้ไขแล้วกดบันทึกเพื่อส่งตรวจอีกครั้ง'),
      'pending' => const NoticeCard(text: 'กำลังรอตรวจสอบ – แก้ไขได้ทันที'),
      'published' || 'hidden' => const NoticeCard(color: AppColors.navy, text: 'แก้ไขแล้วกดบันทึก ข้อมูลใหม่จะแสดงทันที'),
      'suspended' => NoticeCard(
          color: AppColors.danger,
          title: 'ถูกระงับโดยผู้ดูแลระบบ',
          text: 'เหตุผล: ${d.statusReason ?? '-'}\nไม่สามารถแก้ไขได้ กรุณาติดต่อผู้ดูแลระบบ'),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขหอพัก' : 'เพิ่มหอพัก')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: () {
                  setState(() => _loading = true);
                  _load();
                })
              : _form(),
    );
  }

  Widget _form() {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    final ro = _readOnly;
    final notice = _statusNotice();

    return Form(
      key: _formKey,
      child: AbsorbPointer(
        absorbing: ro,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (notice != null) notice,
          if (_dorm != null) Align(alignment: Alignment.centerLeft, child: StatusChip(_dorm!.status)),
          const SectionTitle('ข้อมูลหลัก'),
          TextFormField(key: const Key('f_name'), controller: _name, decoration: const InputDecoration(labelText: 'ชื่อหอพัก *'), validator: _required),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _f.zone,
            decoration: const InputDecoration(labelText: 'โซน *'),
            items: [for (final z in AppConfig.zones) DropdownMenuItem(value: z, child: Text(z))],
            onChanged: (v) => setState(() => _f.zone = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('f_price'),
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: digits,
            decoration: const InputDecoration(labelText: 'ราคาต่อเดือน (บาท) *'),
            validator: (v) => _intMin(v, 1),
          ),
          const SectionTitle('ค่าน้ำ / ค่าไฟ'),
          _rateRow('ค่าน้ำ (บาท)', _water, _f.waterBillingType, (v) => setState(() => _f.waterBillingType = v), decimal),
          const SizedBox(height: 12),
          _rateRow('ค่าไฟ (บาท)', _elec, _f.electricityBillingType, (v) => setState(() => _f.electricityBillingType = v), decimal),
          const SectionTitle('ที่ตั้งและการติดต่อ'),
          TextFormField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'ที่อยู่')),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
            decoration: const InputDecoration(labelText: 'เบอร์ติดต่อ'),
            validator: (v) {
              final t = (v ?? '').replaceAll('-', '').trim();
              if (t.isEmpty) return null;
              return RegExp(r'^0[0-9]{8,9}$').hasMatch(t) ? null : 'เบอร์โทรไม่ถูกต้อง';
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.location_on, color: _f.latitude == null ? AppColors.danger : AppColors.teal),
              title: Text(_f.latitude == null ? 'ยังไม่ได้ปักหมุดตำแหน่ง *' : 'ปักหมุดแล้ว'),
              subtitle: _f.latitude == null ? null : Text('${_f.latitude!.toStringAsFixed(5)}, ${_f.longitude!.toStringAsFixed(5)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickLocation,
            ),
          ),
          const SectionTitle('สิ่งอำนวยความสะดวก'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in _amenities)
              FilterChip(
                label: Text(a.name),
                selected: _f.amenityIds.contains(a.id),
                onSelected: (on) => setState(() => on ? _f.amenityIds.add(a.id) : _f.amenityIds.remove(a.id)),
              ),
          ]),
          const SectionTitle('รายละเอียด'),
          TextFormField(controller: _desc, maxLines: 4, decoration: const InputDecoration(labelText: 'รายละเอียดเพิ่มเติม', alignLabelWithHint: true)),
          SectionTitle('รูปภาพหอพัก * (${_f.images.length})',
              trailing: TextButton.icon(onPressed: _pickImages, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('เพิ่มรูป'))),
          if (_f.images.isEmpty)
            const Text('ยังไม่มีรูป (ต้องมีอย่างน้อย 1 รูป) – รูปแรกจะใช้เป็นรูปหน้าปก', style: TextStyle(color: AppColors.danger))
          else
            SizedBox(
              height: 110,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: true,
                onReorder: (a, b) => setState(() {
                  if (b > a) b--;
                  _f.images.insert(b, _f.images.removeAt(a));
                }),
                children: [
                  for (var i = 0; i < _f.images.length; i++)
                    Padding(
                      key: ValueKey('${_f.images[i]}#$i'),
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(children: [
                        NetImage(_f.images[i], width: 140, height: 110),
                        if (i == 0)
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
                              child: const Text('ปก', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.black45),
                            iconSize: 18,
                            color: Colors.white,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _f.images.removeAt(i)),
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
          const SectionTitle('เอกสารแสดงความเป็นเจ้าของ *'),
          _documentSection(),
          const SizedBox(height: 24),
          if (!ro)
            FilledButton(
              key: const Key('f_save'),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(!_isEdit || _dorm!.status == 'rejected' ? 'บันทึกและส่งตรวจสอบ' : 'บันทึกการแก้ไข'),
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _documentSection() {
    final doc = _f.ownershipDocument;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (doc == null || doc.isEmpty)
            const Text('ยังไม่ได้แนบเอกสาร เช่น โฉนดที่ดิน สัญญาเช่า หรือใบอนุญาตประกอบกิจการหอพัก',
                style: TextStyle(color: AppColors.danger))
          else if (_isImagePath(doc))
            Stack(children: [
              NetImage(doc, height: 160, width: double.infinity),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _f.ownershipDocument = null),
                ),
              ),
            ])
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, color: AppColors.teal),
              title: Text(doc.split('/').last),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _f.ownershipDocument = null)),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: _pickDocImage, icon: const Icon(Icons.photo_outlined), label: const Text('แนบรูปเอกสาร')),
            OutlinedButton.icon(onPressed: _pickDocFile, icon: const Icon(Icons.attach_file), label: const Text('แนบไฟล์ PDF')),
            TextButton(
              onPressed: () => setState(() => _f.ownershipDocument = 'assets/images/demo-ownership.jpg'),
              child: const Text('ใช้เอกสารตัวอย่าง (mock)'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _rateRow(String label, TextEditingController c, String? type, ValueChanged<String?> onType, List<TextInputFormatter> fmt) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 2,
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: fmt,
          decoration: InputDecoration(labelText: label, hintText: 'ว่าง = ไม่ระบุ'),
          validator: _optionalNum,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 3,
        child: DropdownButtonFormField<String>(
          initialValue: type ?? AppConfig.billingTypes.first,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'วิธีคิด'),
          items: [for (final t in AppConfig.billingTypes) DropdownMenuItem(value: t, child: Text(billingLabels[t] ?? t))],
          onChanged: onType,
        ),
      ),
    ]);
  }
}
