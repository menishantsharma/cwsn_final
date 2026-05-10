import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/category_models.dart';
import 'package:go_router/go_router.dart';

void _showDescriptionSheet(BuildContext context, String title, String description) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimensions.spacing12),
          Text(description, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    ),
  );
}

class SubcategoryCard extends StatelessWidget {
  final SubcategoryModel subcategory;

  const SubcategoryCard({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    final desc = subcategory.shortDescription;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.services, extra: subcategory),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        child: Row(
          children: [
            _SubcategoryIcon(imageUrl: subcategory.imageUrl),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subcategory.name, style: AppTextStyles.titleSmall),
                  if (desc != null) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    GestureDetector(
                      onTap: () => _showDescriptionSheet(context, subcategory.name, desc),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Learn more',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
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

class _SubcategoryIcon extends StatelessWidget {
  final String? imageUrl;

  const _SubcategoryIcon({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
              errorWidget: (_, _, _) => const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
            )
          : const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primaryDark,
              size: 20,
            ),
    );
  }
}
