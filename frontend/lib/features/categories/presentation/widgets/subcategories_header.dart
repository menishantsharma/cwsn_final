import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/category_models.dart';

class SubcategoriesHeader extends StatelessWidget {
  final CategoryModel category;

  const SubcategoriesHeader({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.name, style: AppTextStyles.displaySmall),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          'Select a subcategory',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
