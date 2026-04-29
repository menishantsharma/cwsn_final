import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (_) => const SecureStorage(),
);

final dioProvider = Provider(
  (ref) => DioClient(ref.read(secureStorageProvider)).dio,
);
