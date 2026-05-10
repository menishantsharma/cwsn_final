import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/presentation/widgets/request_card.dart';
import 'package:frontend/features/requests/presentation/controllers/request_controller.dart';

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

class RequestsTabView extends ConsumerStatefulWidget {
  const RequestsTabView({super.key});

  @override
  ConsumerState<RequestsTabView> createState() => _RequestsTabViewState();
}

class _RequestsTabViewState extends ConsumerState<RequestsTabView> {
  bool _showPending = true;
  final _pendingScrollController = ScrollController();
  final _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pendingScrollController.addListener(_onPendingScroll);
    _historyScrollController.addListener(_onHistoryScroll);
  }

  @override
  void dispose() {
    _pendingScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onPendingScroll() {
    if (_pendingScrollController.position.pixels <
        _pendingScrollController.position.maxScrollExtent - 200) { return; }
    final state = ref.read(pendingRequestsProvider).asData?.value;
    if (state == null || state.isLoadingMore || !state.hasMore) { return; }
    ref.read(pendingRequestsProvider.notifier).loadMore();
  }

  void _onHistoryScroll() {
    if (_historyScrollController.position.pixels <
        _historyScrollController.position.maxScrollExtent - 200) { return; }
    final state = ref.read(historyRequestsProvider).asData?.value;
    if (state == null || state.isLoadingMore || !state.hasMore) { return; }
    ref.read(historyRequestsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PillSwitcher(
          showPending: _showPending,
          onChanged: (v) => setState(() => _showPending = v),
        ),
        Expanded(
          child: _showPending
              ? _PendingList(scrollController: _pendingScrollController)
              : _HistoryList(scrollController: _historyScrollController),
        ),
      ],
    );
  }
}

class _PillSwitcher extends ConsumerWidget {
  final bool showPending;
  final ValueChanged<bool> onChanged;

  const _PillSwitcher({required this.showPending, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingRequestCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          _Pill(
            label: 'Pending',
            count: pendingCount,
            selected: showPending,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          _Pill(
            label: 'History',
            selected: !showPending,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? Colors.white : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingList extends ConsumerWidget {
  final ScrollController scrollController;
  const _PendingList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingRequestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No pending requests',
            subtitle: 'New service requests will appear here',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(pendingRequestsProvider.notifier).refresh(),
          child: ListView.builder(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: RequestCard(request: state.items[i]),
              );
            },
          ),
        );
      },
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final ScrollController scrollController;
  const _HistoryList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyRequestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No history yet',
            subtitle: 'Accepted and declined requests will appear here',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(historyRequestsProvider.notifier).refresh(),
          child: ListView.builder(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: RequestCard(request: state.items[i]),
              );
            },
          ),
        );
      },
    );
  }
}
