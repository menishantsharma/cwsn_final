import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      data: (notifications) {
        if (notifications.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_outlined,
            title: 'No notifications yet',
            subtitle: 'You\'re all caught up!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing8),
          itemBuilder: (_, i) => NotificationCard(
            notification: notifications[i],
            onTap: () => ref
                .read(notificationProvider.notifier)
                .markAsRead(notifications[i].id),
          ),
        );
      },
    );
  }
}
