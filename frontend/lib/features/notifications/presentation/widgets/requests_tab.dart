import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/load_more_button.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/presentation/widgets/request_card.dart';
import 'package:frontend/features/notifications/presentation/widgets/section_label.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';

class RequestsTab extends ConsumerWidget {
  const RequestsTab({super.key});

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
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$pending',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestsTabView extends ConsumerWidget {
  const RequestsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No requests yet',
            subtitle: 'Incoming service requests will appear here',
          );
        }

        final pending = state.items
            .where((r) => r.status == 'Pending')
            .toList();
        final history = state.items
            .where((r) => r.status != 'Pending')
            .toList();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(requestProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (pending.isNotEmpty) ...[
                SectionLabel('Pending'),
                const SizedBox(height: AppDimensions.spacing12),
                ...pending.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacing8,
                    ),
                    child: RequestCard(request: r),
                  ),
                ),
              ],
              if (history.isNotEmpty) ...[
                if (pending.isNotEmpty)
                  const SizedBox(height: AppDimensions.spacing8),
                SectionLabel('History'),
                const SizedBox(height: AppDimensions.spacing12),
                ...history.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacing8,
                    ),
                    child: RequestCard(request: r),
                  ),
                ),
              ],
              if (state.hasMore)
                LoadMoreButton(
                  isLoading: state.isLoadingMore,
                  onPressed: () =>
                      ref.read(requestProvider.notifier).loadMore(),
                ),
            ],
          ),
        );
      },
    );
  }
}
