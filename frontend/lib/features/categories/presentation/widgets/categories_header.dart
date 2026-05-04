import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';
import 'package:go_router/go_router.dart';

class CategoriesHeader extends StatelessWidget {
  const CategoriesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Find Services', style: AppTextStyles.titleLarge),
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
