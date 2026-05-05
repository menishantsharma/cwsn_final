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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find Services', style: AppTextStyles.displaySmall),
                  const SizedBox(height: AppDimensions.spacing4),
                  Text(
                    'What are you looking for today?',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final unreadNotifs = ref
                    .watch(notificationProvider)
                    .maybeWhen(
                      data: (state) =>
                          state.items.where((n) => !n.isRead).length,
                      orElse: () => 0,
                    );
                final pendingRequests = ref.watch(pendingRequestCountProvider);
                final totalBadge = unreadNotifs + pendingRequests;

                return Stack(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    if (totalBadge > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: AppDimensions.spacing8),
            _HeaderIconButton(
              icon: Icons.person_outline_rounded,
              onTap: () => context.push(AppRoutes.profile),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing24),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
