import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../controller/owner_controller.dart';
import '../../controller/owner_session.dart';
import '../../models/dormitory.dart';
import '../../models/dormitory_details.dart';
import '../theme/owner_theme.dart';
import '../widgets/dormitory_map.dart';
import '../widgets/labeled_input.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface_card.dart';

/// ฟอร์มเพิ่มหอ (ไม่ส่ง dormitory) หรือแก้ไขหอ (ส่ง dormitory) ปิดด้วย true เมื่อบันทึกแล้ว
class DormitoryFormScreen extends StatefulWidget {
  const DormitoryFormScreen({super.key, this.dormitory});

  final Dormitory? dormitory;

  @override
  State<DormitoryFormScreen> createState() => _DormitoryFormScreenState();
}

class _DormitoryFormScreenState extends State<DormitoryFormScreen> with Notifier<DormitoryFormScreen> {
  late final Map<String, TextEditingController> _c;
  late String _zone;
  late WaterBilling _waterBilling;
  late Set<String> _amenities;
  bool _busy = false;

  bool get _editing => widget.dormitory != null;

  static String _plain(num? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void initState() {
    super.initState();
    final d = widget.dormitory;
    final x = d == null ? const DormitoryDetails() : OwnerSession.detailsOf(d.id);
    _c = {
      'name': TextEditingController(text: d?.name ?? ''),
      'rooms': TextEditingController(text: _plain(x.availableRooms)),
      'description': TextEditingController(text: x.description),
      'price': TextEditingController(text: d?.pricePerMonth.toString() ?? ''),
      'deposit': TextEditingController(text: _plain(x.deposit)),
      'water': TextEditingController(text: _plain(x.waterRate)),
      'electric': TextEditingController(text: _plain(x.electricRate)),
      'lat': TextEditingController(text: d?.latitude.toString() ?? ''),
      'lng': TextEditingController(text: d?.longitude.toString() ?? ''),
      'address': TextEditingController(text: x.address),
    };
    _zone = d?.zone ?? dormitoryZones.first;
    _waterBilling = x.waterBilling;
    _amenities = {...x.amenities};
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _c[key]!.text.trim();

  /// ช่องไม่บังคับ: ว่างได้ แต่ถ้ากรอกต้องเป็นตัวเลขไม่ติดลบ
  bool _invalidOptional(String key, {bool whole = false}) {
    final t = _text(key);
    if (t.isEmpty) return false;
    final v = whole ? int.tryParse(t) : double.tryParse(t);
    return v == null || v < 0;
  }

  LatLng? get _picked {
    final lat = double.tryParse(_text('lat'));
    final lng = double.tryParse(_text('lng'));
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  void _pickOnMap(LatLng p) {
    _c['lat']!.text = p.latitude.toStringAsFixed(6);
    _c['lng']!.text = p.longitude.toStringAsFixed(6);
  }

  Future<void> _save() async {
    final position = _picked;
    final price = int.tryParse(_text('price'));
    final String? problem = _text('name').isEmpty
        ? 'กรอกชื่อหอพัก'
        : position == null
            ? 'พิกัดไม่ถูกต้อง แตะบนแผนที่หรือกรอก latitude/longitude เป็นตัวเลข'
            : price == null || price < 0
                ? 'ราคาต้องเป็นจำนวนเต็มตั้งแต่ 0 ขึ้นไป'
                : _invalidOptional('rooms', whole: true)
                    ? 'จำนวนห้องว่างต้องเป็นจำนวนเต็มตั้งแต่ 0 ขึ้นไป'
                    : _invalidOptional('deposit', whole: true)
                        ? 'ค่ามัดจำต้องเป็นจำนวนเต็มตั้งแต่ 0 ขึ้นไป'
                        : (_invalidOptional('water') || _invalidOptional('electric'))
                            ? 'ค่าน้ำและค่าไฟต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป'
                            : null;
    if (problem != null) {
      notify(problem);
      return;
    }

    final body = {
      'name': _text('name'),
      'zone': _zone,
      'latitude': position!.latitude,
      'longitude': position.longitude,
      'price_per_month': price,
    };

    setState(() => _busy = true);
    try {
      final id = _editing ? widget.dormitory!.id : await OwnerController.createDormitory(body);
      if (_editing) await OwnerController.updateDormitory(id!, body);
      if (id != null) {
        // บันทึกแล้วหออยู่ในสถานะ "รอตรวจสอบ" ตามที่แจ้งไว้ในหน้านี้
        OwnerSession.saveDetails(
          id,
          DormitoryDetails(
            availableRooms: int.tryParse(_text('rooms')),
            waterRate: double.tryParse(_text('water')),
            waterBilling: _waterBilling,
            electricRate: double.tryParse(_text('electric')),
            deposit: int.tryParse(_text('deposit')),
            address: _text('address'),
            description: _text('description'),
            amenities: _amenities,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on OwnerException catch (e) {
      notify(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final numeric = const TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'แก้ไขหอพัก' : 'เพิ่มหอพัก')),
      body: SafeArea(
        child: PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(OwnerGap.page, 8, OwnerGap.page, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitledCard(
                  title: 'รูปภาพ',
                  note: '0/10 · รูปแรกเป็นรูปปก',
                  child: Row(
                    children: [
                      Tooltip(
                        message: 'เพิ่มรูป',
                        child: Material(
                          color: OwnerColors.primaryTint,
                          borderRadius: BorderRadius.circular(OwnerRadius.tile),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(OwnerRadius.tile),
                            onTap: () => notify('ยังอัปโหลดรูปไม่ได้ ระบบนี้ยังไม่เปิดใช้งาน'),
                            child: const SizedBox(
                              width: 80,
                              height: 80,
                              child: Icon(Icons.add_photo_alternate_outlined, color: OwnerColors.primaryText),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ยังไม่เปิดใช้งานการอัปโหลดรูป',
                          style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                TitledCard(
                  title: 'ข้อมูลหอ',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledInput(
                        label: 'ชื่อหอ',
                        controller: _c['name']!,
                        maxLength: 100,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      Text('โซน', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final z in dormitoryZones)
                            ChoiceChip(
                              label: Text(z),
                              selected: z == _zone,
                              showCheckmark: false,
                              backgroundColor: OwnerColors.surface,
                              selectedColor: OwnerColors.primary,
                              side: BorderSide(color: z == _zone ? OwnerColors.primary : OwnerColors.fieldBorder),
                              shape: const StadiumBorder(),
                              labelStyle: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: z == _zone ? Colors.white : OwnerColors.text,
                              ),
                              onSelected: (_) => setState(() => _zone = z),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'จำนวนห้องว่าง',
                        controller: _c['rooms']!,
                        optional: true,
                        keyboardType: TextInputType.number,
                        helper: 'ใส่ 0 เมื่อห้องเต็ม นักศึกษาจะเห็นป้าย “เต็ม”',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                TitledCard(
                  title: 'รายละเอียด',
                  child: LabeledInput(
                    label: 'รายละเอียด (Description)',
                    controller: _c['description']!,
                    optional: true,
                    maxLines: 5,
                    maxLength: 1000,
                    hint: 'เช่น ลักษณะห้อง เวลาปิดประตู กฎการเลี้ยงสัตว์ ร้านค้าใกล้เคียง',
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                TitledCard(
                  title: 'ค่าใช้จ่าย',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LabeledInput(
                              label: 'ค่าหอ (บาท/เดือน)',
                              controller: _c['price']!,
                              keyboardType: TextInputType.number,
                              action: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LabeledInput(
                              label: 'ค่ามัดจำ (บาท)',
                              controller: _c['deposit']!,
                              optional: true,
                              keyboardType: TextInputType.number,
                              action: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('ค่าน้ำ', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SegmentedButton<WaterBilling>(
                        expandedInsets: EdgeInsets.zero,
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: WaterBilling.perUnit, label: Text('คิดต่อหน่วย')),
                          ButtonSegment(value: WaterBilling.flat, label: Text('เหมาจ่าย')),
                        ],
                        selected: {_waterBilling},
                        onSelectionChanged: (s) => setState(() => _waterBilling = s.first),
                      ),
                      const SizedBox(height: 8),
                      LabeledInput(
                        label: _waterBilling == WaterBilling.flat ? 'ค่าน้ำ (บาท/คน/เดือน)' : 'ค่าน้ำ (บาท/หน่วย)',
                        controller: _c['water']!,
                        optional: true,
                        keyboardType: numeric,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'ค่าไฟ (บาท/หน่วย)',
                        controller: _c['electric']!,
                        optional: true,
                        keyboardType: numeric,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                TitledCard(
                  title: 'ที่อยู่และตำแหน่ง',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // แผนที่ตามค่าในช่อง lat/lng แตะบนแผนที่เพื่อย้ายหมุด
                      ListenableBuilder(
                        listenable: Listenable.merge([_c['lat']!, _c['lng']!]),
                        builder: (_, _) => DormitoryMap(position: _picked, height: 220, onPick: _pickOnMap),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'แตะบนแผนที่เพื่อปักหมุด หรือกรอกพิกัดด้านล่าง',
                        style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LabeledInput(
                              label: 'Latitude',
                              controller: _c['lat']!,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              action: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LabeledInput(
                              label: 'Longitude',
                              controller: _c['lng']!,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              action: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LabeledInput(
                        label: 'ที่อยู่',
                        controller: _c['address']!,
                        optional: true,
                        maxLines: 3,
                        maxLength: 255,
                        hint: 'บ้านเลขที่ ซอย ถนน ตำบล อำเภอ จังหวัด รหัสไปรษณีย์',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                TitledCard(
                  title: 'สิ่งอำนวยความสะดวก',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in dormitoryAmenities)
                        FilterChip(
                          label: Text(a),
                          selected: _amenities.contains(a),
                          backgroundColor: OwnerColors.surface,
                          selectedColor: OwnerColors.primaryTint,
                          checkmarkColor: OwnerColors.primaryText,
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: _amenities.contains(a) ? OwnerColors.primary : OwnerColors.fieldBorder,
                          ),
                          labelStyle: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _amenities.contains(a) ? OwnerColors.primaryText : OwnerColors.textBody,
                          ),
                          onSelected: (on) => setState(() => on ? _amenities.add(a) : _amenities.remove(a)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: OwnerColors.chip, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    'หลังบันทึก หอจะอยู่ในสถานะ “รอตรวจสอบ” จนกว่า Admin จะอนุมัติ',
                    style: text.bodySmall?.copyWith(color: OwnerColors.navy, height: 1.5),
                  ),
                ),
                const SizedBox(height: OwnerGap.block),
                BusyButton(
                  label: _editing ? 'บันทึกและส่งตรวจใหม่' : 'บันทึกและส่งตรวจ',
                  busy: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
