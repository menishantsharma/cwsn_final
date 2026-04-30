import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Inbox', style: AppTextStyles.titleMedium),
          elevation: 0,
          bottom: TabBar(
            labelStyle: AppTextStyles.labelMedium,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              const Tab(text: 'Notifications'),
              _RequestsTab(),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_NotificationsTab(), _RequestsTabView()],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRequestCountProvider);
    if (pending == 0) return const Tab(text: 'Requests');
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Requests'),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$pending',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications Tab ─────────────────────────────────────

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab();

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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          itemCount: notifications.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spacing12),
          itemBuilder: (_, i) => _NotificationCard(
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

// ── Requests Tab ──────────────────────────────────────────

class _RequestsTabView extends ConsumerWidget {
  const _RequestsTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No requests yet',
            subtitle: 'Incoming service requests will appear here',
          );
        }

        final pending = requests.where((r) => r.status == 'Pending').toList();
        final history = requests.where((r) => r.status != 'Pending').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            if (pending.isNotEmpty) ...[
              Text('Pending', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppDimensions.spacing12),
              ...pending.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacing12,
                  ),
                  child: _RequestCard(request: r),
                ),
              ),
            ],
            if (history.isNotEmpty) ...[
              if (pending.isNotEmpty)
                const SizedBox(height: AppDimensions.spacing8),
              Text('History', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppDimensions.spacing12),
              ...history.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacing12,
                  ),
                  child: _RequestCard(request: r),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final RequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status == 'Pending';
    final isAccepted = request.status == 'Accepted';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.serviceTitle, style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      'From: ${request.cwsnUserName}',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'For: ${request.childName} · ${request.childAge}y · ${request.childGender}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacing12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(request.note!, style: AppTextStyles.bodySmall),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: AppDimensions.spacing16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(requestProvider.notifier).reject(request.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        ref.read(requestProvider.notifier).accept(request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isAccepted && request.caregiverPhone != null) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spacing6),
                Text(request.caregiverPhone!, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Accepted' => Colors.green,
      'Rejected' => Colors.red,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing8,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
