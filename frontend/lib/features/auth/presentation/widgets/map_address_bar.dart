import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';

class MapAddressBar extends StatelessWidget {
  final String address;
  final bool isGeocoding;
  final VoidCallback onConfirm;

  const MapAddressBar({
    super.key,
    required this.address,
    required this.isGeocoding,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                color: address.isEmpty ? AppColors.textHint : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isGeocoding
                    ? const Text(
                        'Finding address...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      )
                    : Text(
                        address.isEmpty
                            ? 'Move the map to select your area'
                            : address,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: address.isEmpty
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
              onPressed: address.isNotEmpty && !isGeocoding ? onConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textHint,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
