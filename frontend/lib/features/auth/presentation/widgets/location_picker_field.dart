import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/pages/map_picker_page.dart';

class LocationPickerField extends StatelessWidget {
  final LocationPickerResult? location;
  final VoidCallback onTap;

  const LocationPickerField({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;

    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: hasLocation
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on_rounded : Icons.map_outlined,
                color: hasLocation ? AppColors.primary : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  location?.displayLocation ?? 'Tap to pick your area on map',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: hasLocation
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
