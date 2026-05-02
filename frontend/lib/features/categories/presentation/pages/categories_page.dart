import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/presentation/providers/category_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';
import 'package:go_router/go_router.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error', style: AppTextStyles.bodyMedium),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories available',
                subtitle: 'Please check back later',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              itemCount: categories.length + 1,
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0 ? AppDimensions.spacing20 : AppDimensions.spacing8,
              ),
              itemBuilder: (context, index) {
                if (index == 0) return _Header();
                return _CategoryCard(category: categories[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Find Services', style: AppTextStyles.displaySmall),
            ),
            Consumer(
              builder: (context, ref, _) {
                final unreadNotifs = ref
                    .watch(notificationProvider)
                    .maybeWhen(
                      data: (list) => list.where((n) => !n.isRead).length,
                      orElse: () => 0,
                    );
                final pendingRequests = ref.watch(pendingRequestCountProvider);
                final totalBadge = unreadNotifs + pendingRequests;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: () => context.push(AppRoutes.notifications),
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.textPrimary,
                    ),
                    if (totalBadge > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.profile),
              icon: const Icon(Icons.person_outline_rounded),
              color: AppColors.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          'Select a category to get started',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacing20),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryCard({required this.category});

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
