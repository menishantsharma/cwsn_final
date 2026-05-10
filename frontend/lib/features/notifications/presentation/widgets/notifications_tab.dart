import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:frontend/features/notifications/presentation/widgets/notification_card.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) { return; }
    final state = ref.read(notificationProvider).asData?.value;
    if (state == null || state.isLoadingMore || !state.hasMore) return;
    ref.read(notificationProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationProvider);

    return notificationsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return EmptyState(
            icon: Icons.notifications_outlined,
            title: 'No notifications yet',
            subtitle: "You're all caught up!",
            onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
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
