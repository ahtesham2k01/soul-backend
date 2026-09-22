import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/api_client.dart';
import 'core/session_store.dart';
import 'core/push_registration_service.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/native_identity_service.dart';
import 'features/bootstrap/bootstrap_repository.dart';
import 'features/chat/chat_repository.dart';
import 'features/discovery/discovery_repository.dart';
import 'features/events/event_repository.dart';
import 'features/profile/profile_repository.dart';
import 'features/safety/safety_repository.dart';

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(const FlutterSecureStorage()),
);

final apiClientProvider = Provider<SoulApiClient>(
  (ref) => SoulApiClient(ref.watch(sessionStoreProvider)),
);

final bootstrapProvider = FutureProvider<BootstrapState>(
  (ref) => BootstrapRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ).load(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);

final nativeIdentityProvider = Provider<NativeIdentityService>(
  (_) => NativeIdentityService(),
);

final pushRegistrationServiceProvider = Provider<PushRegistrationService>(
  (ref) {
    final service = PushRegistrationService(
      ref.watch(apiClientProvider),
      ref.watch(sessionStoreProvider),
    );
    ref.onDispose(() {
      service.dispose();
    });
    return service;
  },
);

/// A token is never trusted locally. The API confirms it and supplies the
/// account state on every cold launch, so onboarding cannot be bypassed.
final sessionRouteProvider = FutureProvider<String>((ref) async {
  final sessions = ref.watch(sessionStoreProvider);
  if (await sessions.readToken() == null) return 'auth';
  try {
    final api = ref.watch(apiClientProvider);
    final accountStatus = await api.get('auth/status');
    final status = accountStatus['status']?.toString();
    if (status == 'blocked') return 'appeal';
    if (status == 'deletion_scheduled') return 'deletion';
    if (status != 'active') return 'account_unavailable';

    final account = await api.get('auth/me');
    final nextStep = account['next_step']?.toString();
    if (nextStep == 'onboarding') return 'onboarding';
    final consent = await api.get('legal/consent');
    final legal = consent['legal'];
    if (legal is Map && legal['requires_acceptance'] == true) return 'legal';
    return 'home';
  } on SoulApiFailure catch (failure) {
    if (failure.statusCode == 401) return 'auth';
    rethrow;
  }
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepository(ref.watch(apiClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStoreProvider),
  ),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepository(ref.watch(apiClientProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(apiClientProvider)),
);
