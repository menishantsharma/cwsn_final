import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/domain/profile_models.dart';

class ChildRow extends StatelessWidget {
  final ChildProfileModel child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChildRow({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${child.age} yrs · ${child.gender}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Text(
              'Edit',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          GestureDetector(
            onTap: onDelete,
            child: Text(
              'Remove',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
