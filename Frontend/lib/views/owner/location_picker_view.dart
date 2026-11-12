import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config.dart';
import '../../core/theme.dart';

/// Tap on the map to set the dorm's coordinates (OpenStreetMap)
class LocationPickerView extends StatefulWidget {
  const LocationPickerView({super.key, this.initial});
  final LatLng? initial;

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  LatLng? _point;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final campus = LatLng(AppConfig.campusLat, AppConfig.campusLng);
    return Scaffold(
      appBar: AppBar(title: const Text('ปักหมุดตำแหน่งหอพัก')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _point ?? campus,
              initialZoom: 16,
              onTap: (_, latLng) => setState(() => _point = latLng),
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hophak.app'),
              MarkerLayer(markers: [
                Marker(point: campus, width: 40, height: 40, child: const Icon(Icons.school, color: AppColors.navy, size: 32)),
                if (_point != null)
                  Marker(
                    point: _point!,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_pin, color: AppColors.danger, size: 48),
                  ),
              ]),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _point == null
                      ? 'แตะบนแผนที่เพื่อปักหมุดตำแหน่งหอพัก'
                      : 'พิกัด: ${_point!.latitude.toStringAsFixed(6)}, ${_point!.longitude.toStringAsFixed(6)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _point == null ? null : () => Navigator.pop(context, _point),
            child: const Text('ยืนยันตำแหน่ง'),
          ),
        ),
      ),
    );
  }
}
