import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';

class MyServicesCard extends ConsumerWidget {
  const MyServicesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allMyServicesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
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
            child: Text(
              'My Services',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
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
            data: (services) => services.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    child: Text('No services added yet', style: AppTextStyles.bodySmall),
                  )
                : Column(
                    children: services
                        .map(
                          (service) => InkWell(
                            onTap: () => context.push(
                              AppRoutes.editableServiceDetail,
                              extra: service,
                            ),
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
                                          style: AppTextStyles.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
