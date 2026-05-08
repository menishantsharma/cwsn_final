import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (_) => const SecureStorage(),
);

// Incremented by AuthInterceptor on 401; authProvider watches this to trigger logout.
final unauthorizedEventProvider = NotifierProvider<UnauthorizedNotifier, int>(
  UnauthorizedNotifier.new,
);

class UnauthorizedNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state++;
}

final dioProvider = Provider((ref) {
  final storage = ref.read(secureStorageProvider);
  final notifier = ref.read(unauthorizedEventProvider.notifier);
  return DioClient(
    storage,
    onUnauthorized: () async => notifier.trigger(),
  ).dio;
});
