import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/support/data/issue_repository.dart';

class IssueNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Throws on failure. Caller should `try/catch` to show error UI.
  Future<void> submit(String description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(issueRepositoryProvider).reportIssue(description),
    );
    if (state.hasError) throw state.error!;
  }
}

final issueProvider = AsyncNotifierProvider.autoDispose<IssueNotifier, void>(
  IssueNotifier.new,
);
