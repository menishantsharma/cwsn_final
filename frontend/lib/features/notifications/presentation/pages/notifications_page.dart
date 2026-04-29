import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.titleMedium),
        elevation: 0,
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) =>
              Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Column(
                children: [
                  Expanded(
                    child: EmptyState(
                      icon: Icons.notifications_outlined,
                      title: 'No notifications yet',
                      subtitle: 'You\'re all caught up!',
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              itemBuilder: (context, index) {
                return _NotificationCard(
                  notification: notifications[index],
                  onTap: () => ref
                      .read(notificationProvider.notifier)
                      .markAsRead(notifications[index].id),
                );
              },
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0
                    ? AppDimensions.spacing24
                    : AppDimensions.spacing12,
              ),
              itemCount: notifications.length + 1,
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notification.isRead
                    ? Colors.transparent
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTextStyles.titleSmall),
                  const SizedBox(height: AppDimensions.spacing4),
                  Text(notification.message, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
