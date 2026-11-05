import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../services/api_service.dart';

// ใช้ฟอร์มเดียวกันทั้งเพิ่มและแก้ไข
// ถ้าส่ง dormitory มาด้วยคือแก้ไข ถ้าไม่ส่งคือเพิ่มใหม่
class DormitoryFormScreen extends StatefulWidget {
  final Dormitory? dormitory;

  const DormitoryFormScreen({super.key, this.dormitory});

  @override
  State<DormitoryFormScreen> createState() => _DormitoryFormScreenState();
}

class _DormitoryFormScreenState extends State<DormitoryFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _priceController;
  late String _zone;
  bool _loading = false;

  bool get _isEdit => widget.dormitory != null;

  @override
  void initState() {
    super.initState();
    final d = widget.dormitory;
    _nameController = TextEditingController(text: d?.name ?? '');
    _latController = TextEditingController(text: d?.latitude.toString() ?? '');
    _lngController = TextEditingController(text: d?.longitude.toString() ?? '');
    _priceController = TextEditingController(text: d?.pricePerMonth.toString() ?? '');
    _zone = d?.zone ?? dormitoryZones.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final price = int.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      _showMessage('กรอกชื่อหอพัก');
      return;
    }
    if (lat == null || lng == null) {
      _showMessage('latitude และ longitude ต้องเป็นตัวเลข');
      return;
    }
    if (price == null) {
      _showMessage('ราคาต้องเป็นจำนวนเต็ม');
      return;
    }

    final body = {
      'name': name,
      'zone': _zone,
      'latitude': lat,
      'longitude': lng,
      'price_per_month': price,
    };

    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await ApiService.updateDormitory(widget.dormitory!.id, body);
      } else {
        await ApiService.createDormitory(body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('เชื่อมต่อ server ไม่ได้');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขหอพัก' : 'เพิ่มหอพัก')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อหอพัก', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _zone,
                  decoration: const InputDecoration(labelText: 'โซน', border: OutlineInputBorder()),
                  items: dormitoryZones
                      .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _zone = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ราคาต่อเดือน (บาท)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('บันทึก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
