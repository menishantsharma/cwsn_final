import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/support/data/sources/issue_remote_source.dart';
import 'package:frontend/providers/core_providers.dart';

final issueRemoteSourceProvider = Provider<IssueRemoteSource>(
  (ref) => IssueRemoteSource(ref.read(dioProvider)),
);

class IssueNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit(String description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(issueRemoteSourceProvider).reportIssue(description),
    );
    return state is! AsyncError;
  }
}

final issueProvider = AsyncNotifierProvider.autoDispose<IssueNotifier, void>(
  IssueNotifier.new,
);
