import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

class ServicesHeader extends StatelessWidget {
  final SubcategoryModel subcategory;

  const ServicesHeader({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subcategory.name, style: AppTextStyles.displaySmall),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          'Available services',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacing16),
      ],
    );
  }
}
