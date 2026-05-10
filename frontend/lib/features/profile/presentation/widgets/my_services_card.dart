import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/interactions/presentation/controllers/upvote_controller.dart';
import 'package:frontend/features/services/domain/service_models.dart';
import 'package:frontend/features/services/presentation/controllers/service_controller.dart';

class MyServicesCard extends ConsumerWidget {
  const MyServicesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allMyServicesProvider);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              AppDimensions.spacing12,
            ),
            child: Text('My Services', style: AppTextStyles.titleSmall),
          ),
          const Divider(height: 1, color: AppColors.border),
          servicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppDimensions.spacing16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              child: Text('Failed to load services', style: AppTextStyles.bodySmall),
            ),
            data: (state) => state.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    child: Text(
                      'No services added yet',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Column(
                    children: state.items
                        .map((service) => _ServiceRow(service: service))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends ConsumerWidget {
  final ServiceModel service;
  const _ServiceRow({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));

    return InkWell(
      onTap: () => context.push(AppRoutes.editableServiceDetail, extra: service.id),
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.serviceType} · ${service.paymentType}',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.thumb_up_outlined, size: 12, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  '${service.upvoteCount + delta}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
