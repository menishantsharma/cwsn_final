import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/interactions/presentation/providers/upvote_provider.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/widgets/service_chip.dart';

class MyServiceCard extends ConsumerWidget {
  final ServiceModel service;

  const MyServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));

    return GestureDetector(
      onTap: () => context.push(AppRoutes.editableServiceDetail, extra: service),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.primary,
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: Radius.circular(AppDimensions.radiusXl),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                            child: Text(
                              'YOUR SERVICE',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 9,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing6),
                      Text(
                        service.title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_outlined, size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${service.upvoteCount + delta}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing6),
                    const Icon(Icons.edit_outlined, size: 14, color: AppColors.textHint),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              children: [
                ServiceChip(label: service.serviceType),
                const SizedBox(width: AppDimensions.spacing6),
                ServiceChip(label: service.paymentType),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
