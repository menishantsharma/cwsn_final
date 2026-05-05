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

class ProfileServiceCard extends ConsumerWidget {
  final ServiceModel service;

  const ProfileServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));
    final upvotes = service.upvoteCount + delta;
    final hasDescription =
        service.description != null && service.description!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.editableServiceDetail, extra: service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusXl),
                    bottomLeft: Radius.circular(AppDimensions.radiusXl),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              service.title,
                              style: AppTextStyles.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacing12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.thumb_up_rounded,
                                    size: 12,
                                    color: upvotes > 0
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$upvotes',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: upvotes > 0
                                          ? AppColors.primary
                                          : AppColors.textHint,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacing4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: AppDimensions.spacing6),
                        Text(
                          service.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }
}
