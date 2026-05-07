import 'package:cached_network_image/cached_network_image.dart';
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


class ServiceCard extends ConsumerWidget {
  final ServiceModel service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));
    final caregiver = service.caregiverProfile;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail, extra: service.id),
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
        padding: const EdgeInsets.all(AppDimensions.spacing16),
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
                const SizedBox(width: AppDimensions.spacing8),
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
            if (caregiver != null) ...[
              const SizedBox(height: AppDimensions.spacing12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacing12),
              Row(
                children: [
                  CaregiverAvatar(name: caregiver.name, imageUrl: service.image),
                  const SizedBox(width: AppDimensions.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiver.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (caregiver.streetAddress != null &&
                            caregiver.streetAddress!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 11, color: AppColors.textHint),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  caregiver.streetAddress!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CaregiverAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const CaregiverAvatar({super.key, required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          placeholder: (_, _) => _initials(),
          errorWidget: (_, _, _) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
