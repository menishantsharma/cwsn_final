import 'package:flutter/material.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:go_router/go_router.dart';

class SubcategoryCard extends StatelessWidget {
  final SubcategoryModel subcategory;

  const SubcategoryCard({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.services, extra: subcategory),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subcategory.name, style: AppTextStyles.titleSmall),
                  if (subcategory.shortDescription != null) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      subcategory.shortDescription!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
