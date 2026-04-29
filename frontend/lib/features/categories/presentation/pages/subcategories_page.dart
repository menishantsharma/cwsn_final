import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

class SubcategoriesPage extends StatelessWidget {
  final CategoryModel category;

  const SubcategoriesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final subcategories = category.subcategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: subcategories.isEmpty
            ? const EmptyState(
                icon: Icons.list_outlined,
                title: 'No subcategories found',
                subtitle: 'This category has no subcategories yet',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: AppDimensions.spacing32,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) return _Header(category: category);
                  return _SubcategoryCard(
                    subcategory: subcategories[index - 1],
                  );
                },
                separatorBuilder: (_, i) => SizedBox(
                  height: i == 0
                      ? AppDimensions.spacing24
                      : AppDimensions.spacing12,
                ),
                itemCount: subcategories.length + 1,
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CategoryModel category;

  const _Header({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.name, style: AppTextStyles.displaySmall),
        const SizedBox(height: AppDimensions.spacing8),
        Text('Select a subcategory', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final SubcategoryModel subcategory;

  const _SubcategoryCard({required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to services
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subcategory.name, style: AppTextStyles.titleSmall),
                  if (subcategory.shortDescription != null) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      subcategory.shortDescription!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
