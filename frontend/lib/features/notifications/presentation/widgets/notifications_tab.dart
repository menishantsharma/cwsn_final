import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/load_more_button.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/notifications/presentation/widgets/notification_card.dart';

class NotificationsTab extends ConsumerWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return notificationsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return const EmptyState(
            icon: Icons.notifications_outlined,
            title: 'No notifications yet',
            subtitle: 'You\'re all caught up!',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(notificationProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == state.items.length) {
                return LoadMoreButton(
                  isLoading: state.isLoadingMore,
                  onPressed: () =>
                      ref.read(notificationProvider.notifier).loadMore(),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: NotificationCard(
                  notification: state.items[i],
                  onTap: () => ref
                      .read(notificationProvider.notifier)
                      .markAsRead(state.items[i].id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
