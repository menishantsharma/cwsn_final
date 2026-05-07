import 'package:flutter_riverpod/flutter_riverpod.dart';

class PagedResponse<T> {
  final List<T> results;
  final bool hasMore;
  const PagedResponse({required this.results, required this.hasMore});
}

class PaginatedState<T> {
  final List<T> items;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final int currentPage;

  const PaginatedState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.currentPage = 1,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    int? currentPage,
  }) => PaginatedState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    currentPage: currentPage ?? this.currentPage,
  );
}

abstract class PaginatedNotifier<T> extends AsyncNotifier<PaginatedState<T>> {
  Future<PagedResponse<T>> fetchPage(int page);

  @override
  Future<PaginatedState<T>> build() async {
    final page = await fetchPage(1);
    return PaginatedState(
      items: page.results,
      hasMore: page.hasMore,
      currentPage: 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    final page = await fetchPage(nextPage);

    final latest = state.asData?.value;
    if (latest == null || !latest.isLoadingMore) return;
    state = AsyncData(
      latest.copyWith(
        items: [...current.items, ...page.results],
        hasMore: page.hasMore,
        isLoadingMore: false,
        currentPage: nextPage,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null || current.isRefreshing) return;
    state = AsyncData(current.copyWith(isRefreshing: true));
    try {
      final page = await fetchPage(1);
      state = AsyncData(PaginatedState(
        items: page.results,
        hasMore: page.hasMore,
        currentPage: 1,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isRefreshing: false));
    }
  }

  void reset() {
    ref.invalidateSelf();
  }
}

// Family variant — for notifiers that take a parameter (subcategories, filtered services)
abstract class PaginatedFamilyNotifier<T, Arg>
    extends AsyncNotifier<PaginatedState<T>> {
  Arg get arg;
  Future<PagedResponse<T>> fetchPage(Arg arg, int page);

  @override
  Future<PaginatedState<T>> build() async {
    final page = await fetchPage(arg, 1);
    return PaginatedState(
      items: page.results,
      hasMore: page.hasMore,
      currentPage: 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    final page = await fetchPage(arg, nextPage);

    final latest = state.asData?.value;
    if (latest == null || !latest.isLoadingMore) return;
    state = AsyncData(
      latest.copyWith(
        items: [...current.items, ...page.results],
        hasMore: page.hasMore,
        isLoadingMore: false,
        currentPage: nextPage,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null || current.isRefreshing) return;
    state = AsyncData(current.copyWith(isRefreshing: true));
    try {
      final page = await fetchPage(arg, 1);
      state = AsyncData(PaginatedState(
        items: page.results,
        hasMore: page.hasMore,
        currentPage: 1,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isRefreshing: false));
    }
  }

  void reset() {
    ref.invalidateSelf();
  }
}
