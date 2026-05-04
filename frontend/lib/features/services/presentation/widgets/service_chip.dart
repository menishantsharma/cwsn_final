import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

IconData _chipIcon(String label) {
  switch (label.toLowerCase()) {
    case 'online':
      return Icons.wifi_rounded;
    case 'offline':
      return Icons.people_outlined;
    case 'hybrid':
      return Icons.devices_rounded;
    case 'paid':
      return Icons.attach_money_rounded;
    case 'unpaid':
      return Icons.volunteer_activism_rounded;
    default:
      return Icons.label_outline_rounded;
  }
}

class ServiceChip extends StatelessWidget {
  final String label;

  const ServiceChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final icon = _chipIcon(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryDark,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon chip used on service detail / create pages.
class ServiceDetailChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const ServiceDetailChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: AppDimensions.spacing4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
