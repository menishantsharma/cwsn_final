import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:frontend/features/requests/presentation/controllers/request_controller.dart';
import 'package:go_router/go_router.dart';

/// Scrollable greeting — title + icons. Scrolls away with content.
class CategoriesGreeting extends StatelessWidget {
  const CategoriesGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
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
              final unreadNotifs = ref.watch(unreadCountProvider).maybeWhen(data: (c) => c, orElse: () => 0);
              final pendingRequests = ref.watch(pendingCountProvider).maybeWhen(data: (c) => c, orElse: () => 0);
              final totalBadge = unreadNotifs + pendingRequests;

              return Stack(
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () async {
                      await context.push(AppRoutes.notifications);
                      ref.invalidate(unreadCountProvider);
                      ref.invalidate(pendingCountProvider);
                    },
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
    );
  }
}

/// Pinned search bar — stays visible as user scrolls.
class CategoriesSearchBar extends StatelessWidget {
  const CategoriesSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.searchResults),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
              const SizedBox(width: AppDimensions.spacing8),
              Text(
                'Search services...',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
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
