import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/api_client.dart';
import 'core/session_store.dart';
import 'features/auth/auth_repository.dart';
import 'features/bootstrap/bootstrap_repository.dart';

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(const FlutterSecureStorage()),
);

final apiClientProvider = Provider<SoulApiClient>(
  (ref) => SoulApiClient(ref.watch(sessionStoreProvider)),
);

final bootstrapProvider = FutureProvider<BootstrapState>(
  (ref) => BootstrapRepository(ref.watch(apiClientProvider)).load(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);

/// A token is never trusted locally. The API must confirm it on every cold launch.
final sessionRouteProvider = FutureProvider<String>((ref) async {
  final sessions = ref.watch(sessionStoreProvider);
  if (await sessions.readToken() == null) return 'auth';
  try {
    await ref.watch(apiClientProvider).get('auth/me');
    return 'home';
  } on SoulApiFailure catch (failure) {
    if (failure.statusCode == 401) return 'auth';
    rethrow;
  }
});
