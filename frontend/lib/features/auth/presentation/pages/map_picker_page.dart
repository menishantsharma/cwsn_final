import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerResult {
  final String address;
  final String subLocality;
  final String city;
  final String state;
  final double latitude;
  final double longitude;

  const LocationPickerResult({
    required this.address,
    required this.subLocality,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  /// "Powai, Mumbai, Maharashtra"
  String get displayLocation {
    final parts = [subLocality, city, state]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : address;
  }
}

class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const _defaultCenter = LatLng(19.0760, 72.8777);

  final MapController _mapController = MapController();
  LatLng _center = _defaultCenter;
  String _address = '';
  String _subLocality = '';
  String _city = '';
  String _state = '';
  bool _isGeocoding = false;
  bool _isLocating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLat != null && widget.initialLng != null) {
        _mapController.move(_center, 15);
        _reverseGeocode(_center);
      } else {
        _goToCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          _showSnack('Please enable location services');
          setState(() => _isLocating = false);
        }
        _reverseGeocode(_center);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnack('Location permission is required');
          setState(() => _isLocating = false);
        }
        _reverseGeocode(_center);
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _center = loc;
        _isLocating = false;
      });
      _mapController.move(loc, 15);
      _reverseGeocode(loc);
    } catch (_) {
      if (mounted) {
        _showSnack('Could not get current location');
        setState(() => _isLocating = false);
      }
      _reverseGeocode(_center);
    }
  }

  void _onMapMove(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    setState(() => _center = camera.center);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(camera.center);
    });
  }

  Future<void> _reverseGeocode(LatLng loc) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final marks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        debugPrint('geocoding result: name=${p.name}, street=${p.street}, subLocality=${p.subLocality}, locality=${p.locality}, subAdminArea=${p.subAdministrativeArea}, adminArea=${p.administrativeArea}, country=${p.country}, postalCode=${p.postalCode}');
        final parts = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty);
        setState(() {
          _subLocality = p.subLocality ?? '';
          _city = p.locality ?? '';
          _state = p.administrativeArea ?? '';
          _address = parts.isNotEmpty
              ? parts.join(', ')
              : '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _address =
            '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}');
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _confirm() {
    if (_address.isEmpty) return;
    Navigator.of(context).pop(
      LocationPickerResult(
        address: _address,
        subLocality: _subLocality,
        city: _city,
        state: _state,
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick your location'),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: _onMapMove,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cwsn',
              ),
            ],
          ),

          // Fixed center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_pin,
                size: 44,
                color: AppColors.primary,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // Pin shadow dot
          Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Zoom + GPS buttons
          Positioned(
            right: 16,
            bottom: 160,
            child: Column(
              children: [
                _mapButton(
                  heroTag: 'zoom_in',
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                    _center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _mapButton(
                  heroTag: 'zoom_out',
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                    _center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 8),
                _mapButton(
                  heroTag: 'gps',
                  icon: Icons.my_location_rounded,
                  onTap: _isLocating ? null : _goToCurrentLocation,
                  loading: _isLocating,
                ),
              ],
            ),
          ),

          // Bottom address bar + confirm button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: _address.isEmpty
                            ? AppColors.textHint
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isGeocoding
                            ? const Text(
                                'Finding address...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textHint,
                                ),
                              )
                            : Text(
                                _address.isEmpty
                                    ? 'Move the map to select your area'
                                    : _address,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _address.isEmpty
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _address.isNotEmpty && !_isGeocoding
                          ? _confirm
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textHint,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLg),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required String heroTag,
    required IconData icon,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}
