import 'package:flutter/material.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:go_router/go_router.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final subCount = category.subcategories.length;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.subcategories, extra: category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTextStyles.titleSmall),
                  if (category.shortDescription != null) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      category.shortDescription!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacing8),
                  Text(
                    '$subCount ${subCount == 1 ? 'subcategory' : 'subcategories'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
