import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:go_router/go_router.dart';

class ServicesPage extends ConsumerWidget {
  final SubcategoryModel subcategory;

  const ServicesPage({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(
      serviceProvider((subcategory.categoryId, subcategory.id)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Something went wrong')),
          data: (services) => services.isEmpty
              ? const EmptyState(
                  icon: Icons.design_services_outlined,
                  title: 'No services found',
                  subtitle: 'No services available in this subcategory yet',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: AppDimensions.spacing32,
                  ),
                  itemCount: services.length + 1,
                  separatorBuilder: (_, i) => SizedBox(
                    height: i == 0
                        ? AppDimensions.spacing24
                        : AppDimensions.spacing12,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) return _Header(subcategory: subcategory);
                    return _ServiceCard(service: services[index - 1]);
                  },
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final SubcategoryModel subcategory;

  const _Header({required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subcategory.name, style: AppTextStyles.displaySmall),
        SizedBox(height: AppDimensions.spacing8),
        Text('Available services', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing8,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail, extra: service),
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
                Icons.design_services_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title, style: AppTextStyles.titleSmall),
                  if (service.description != null) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      service.description!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacing8),
                  Row(
                    children: [
                      _Chip(label: service.serviceType),
                      const SizedBox(width: AppDimensions.spacing8),
                      _Chip(label: service.paymentType),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            Icon(
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
