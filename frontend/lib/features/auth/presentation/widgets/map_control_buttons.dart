import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:latlong2/latlong.dart';

class MapControlButtons extends StatelessWidget {
  final MapController mapController;
  final LatLng center;
  final bool isLocating;
  final VoidCallback onGoToCurrentLocation;

  const MapControlButtons({
    super.key,
    required this.mapController,
    required this.center,
    required this.isLocating,
    required this.onGoToCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapButton(
          heroTag: 'zoom_in',
          icon: Icons.add,
          onTap: () => mapController.move(
            center,
            mapController.camera.zoom + 1,
          ),
        ),
        const SizedBox(height: 8),
        _MapButton(
          heroTag: 'zoom_out',
          icon: Icons.remove,
          onTap: () => mapController.move(
            center,
            mapController.camera.zoom - 1,
          ),
        ),
        const SizedBox(height: 8),
        _MapButton(
          heroTag: 'gps',
          icon: Icons.my_location_rounded,
          onTap: isLocating ? null : onGoToCurrentLocation,
          loading: isLocating,
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  const _MapButton({
    required this.heroTag,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
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
