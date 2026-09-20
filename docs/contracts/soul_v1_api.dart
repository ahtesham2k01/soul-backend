// GENERATED FILE. DO NOT EDIT.
// Source: docs/SOUL_V1_MASTER_DOCUMENTATION.md

class SoulApiEndpoint {
  const SoulApiEndpoint({
    required this.operationId,
    required this.method,
    required this.pathTemplate,
    required this.requiresBearerToken,
  });

  final String operationId;
  final String method;
  final String pathTemplate;
  final bool requiresBearerToken;

  String path(Map<String, Object> parameters) {
    var resolved = pathTemplate;
    for (final entry in parameters.entries) {
      resolved = resolved.replaceAll(
        '{${entry.key}}',
        Uri.encodeComponent(entry.value.toString()),
      );
    }
    if (RegExp(r'{[^}]+}').hasMatch(resolved)) {
      throw ArgumentError('Missing path parameter for $pathTemplate');
    }
    return resolved;
  }
}

abstract final class SoulV1Api {
  static const basePath = '/api/v1';

  static const endpoints = <SoulApiEndpoint>[
    SoulApiEndpoint(
      operationId: 'api.v1.health',
      method: 'GET',
      pathTemplate: '/health',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.health.ready',
      method: 'GET',
      pathTemplate: '/health/ready',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.bootstrap',
      method: 'GET',
      pathTemplate: '/bootstrap',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.catalogs.profile',
      method: 'GET',
      pathTemplate: '/catalogs/profile',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.register.request-otp',
      method: 'POST',
      pathTemplate: '/auth/register/request-otp',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.register.verify-otp',
      method: 'POST',
      pathTemplate: '/auth/register/verify-otp',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.login.request-otp',
      method: 'POST',
      pathTemplate: '/auth/login/request-otp',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.login.verify-otp',
      method: 'POST',
      pathTemplate: '/auth/login/verify-otp',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.google',
      method: 'POST',
      pathTemplate: '/auth/google',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.apple',
      method: 'POST',
      pathTemplate: '/auth/apple',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.status.show',
      method: 'GET',
      pathTemplate: '/auth/status',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.me',
      method: 'GET',
      pathTemplate: '/auth/me',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.preferences.update',
      method: 'PUT',
      pathTemplate: '/auth/preferences',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.logout',
      method: 'POST',
      pathTemplate: '/auth/logout',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.logout-all',
      method: 'POST',
      pathTemplate: '/auth/logout-all',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.devices.index',
      method: 'GET',
      pathTemplate: '/auth/devices',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.auth.devices.destroy',
      method: 'DELETE',
      pathTemplate: '/auth/devices/{session}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.location.resolve',
      method: 'POST',
      pathTemplate: '/location/resolve',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.religion-options',
      method: 'GET',
      pathTemplate: '/onboarding/religion-options',
      requiresBearerToken: false,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.religion-profile.show',
      method: 'GET',
      pathTemplate: '/onboarding/religion-profile',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.religion-profile.store',
      method: 'PUT',
      pathTemplate: '/onboarding/religion-profile',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.profile.show',
      method: 'GET',
      pathTemplate: '/onboarding/profile',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.profile.update',
      method: 'PUT',
      pathTemplate: '/onboarding/profile',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.readiness.show',
      method: 'GET',
      pathTemplate: '/onboarding/readiness',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.submit',
      method: 'POST',
      pathTemplate: '/onboarding/submit',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.status',
      method: 'GET',
      pathTemplate: '/onboarding/status',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.resubmit',
      method: 'POST',
      pathTemplate: '/onboarding/resubmit',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.photos.index',
      method: 'GET',
      pathTemplate: '/onboarding/photos',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.photos.upload-session.create',
      method: 'POST',
      pathTemplate: '/onboarding/photos/upload-session',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.photos.register',
      method: 'PUT',
      pathTemplate: '/onboarding/photos/{position}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.photos.visibility.update',
      method: 'PUT',
      pathTemplate: '/onboarding/photos/{position}/visibility',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.onboarding.photos.delete',
      method: 'DELETE',
      pathTemplate: '/onboarding/photos/{position}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.discovery.preferences.show',
      method: 'GET',
      pathTemplate: '/discovery/preferences',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.discovery.preferences.update',
      method: 'PUT',
      pathTemplate: '/discovery/preferences',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.discovery.candidates.index',
      method: 'GET',
      pathTemplate: '/discovery/candidates',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.profiles.show',
      method: 'GET',
      pathTemplate: '/profiles/{profile}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.matching.decisions.store',
      method: 'POST',
      pathTemplate: '/profiles/{profile}/decision',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.likes.received.index',
      method: 'GET',
      pathTemplate: '/likes/received',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.likes.update',
      method: 'PUT',
      pathTemplate: '/profiles/{profile}/like',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.likes.destroy',
      method: 'DELETE',
      pathTemplate: '/profiles/{profile}/like',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.matches.index',
      method: 'GET',
      pathTemplate: '/matches',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.matches.destroy',
      method: 'DELETE',
      pathTemplate: '/matches/{match}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photo-access.index',
      method: 'GET',
      pathTemplate: '/private-photo-access',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photo-access.store',
      method: 'POST',
      pathTemplate: '/matches/{match}/private-photo-access',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photo-access.update',
      method: 'PUT',
      pathTemplate: '/private-photo-access/{accessRequest}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photo-access.destroy',
      method: 'DELETE',
      pathTemplate: '/private-photo-access/{accessRequest}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photos.index',
      method: 'GET',
      pathTemplate: '/matches/{match}/private-photos',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photos.content',
      method: 'GET',
      pathTemplate: '/private-photos/{photo}/content',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.private-photos.capture-events.store',
      method: 'POST',
      pathTemplate: '/private-photos/{photo}/capture-events',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.messages.index',
      method: 'GET',
      pathTemplate: '/matches/{match}/messages',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.messages.store',
      method: 'POST',
      pathTemplate: '/matches/{match}/messages',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.messages.read',
      method: 'POST',
      pathTemplate: '/matches/{match}/messages/read',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.chat.presence.show',
      method: 'GET',
      pathTemplate: '/matches/{match}/presence',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.chat.typing.update',
      method: 'PUT',
      pathTemplate: '/matches/{match}/typing',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.safety.blocks.index',
      method: 'GET',
      pathTemplate: '/blocks',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.safety.blocks.store',
      method: 'POST',
      pathTemplate: '/profiles/{profile}/block',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.safety.blocks.destroy',
      method: 'DELETE',
      pathTemplate: '/profiles/{profile}/block',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.safety.reports.store',
      method: 'POST',
      pathTemplate: '/profiles/{profile}/report',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.account-appeal.show',
      method: 'GET',
      pathTemplate: '/account-appeal',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.account-appeal.store',
      method: 'POST',
      pathTemplate: '/account-appeal',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.verification.cases.index',
      method: 'GET',
      pathTemplate: '/verification/cases',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.verification.summary',
      method: 'GET',
      pathTemplate: '/verification/summary',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.verification.cases.store',
      method: 'POST',
      pathTemplate: '/verification/cases',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.verification.appeals.store',
      method: 'POST',
      pathTemplate: '/verification/cases/{case}/appeal',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.devices.store',
      method: 'POST',
      pathTemplate: '/devices',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.devices.destroy',
      method: 'DELETE',
      pathTemplate: '/devices/{device}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.notification-preferences.show',
      method: 'GET',
      pathTemplate: '/notification-preferences',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.notification-preferences.update',
      method: 'PUT',
      pathTemplate: '/notification-preferences',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.notifications.index',
      method: 'GET',
      pathTemplate: '/notifications',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.notifications.read',
      method: 'POST',
      pathTemplate: '/notifications/{notification}/read',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.events.index',
      method: 'GET',
      pathTemplate: '/events',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.events.show',
      method: 'GET',
      pathTemplate: '/events/{event}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.events.registration.store',
      method: 'POST',
      pathTemplate: '/events/{event}/registration',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.events.registration.destroy',
      method: 'DELETE',
      pathTemplate: '/events/{event}/registration',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.events.reports.store',
      method: 'POST',
      pathTemplate: '/events/{event}/report',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.legal.consent.show',
      method: 'GET',
      pathTemplate: '/legal/consent',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.legal.consent.store',
      method: 'POST',
      pathTemplate: '/legal/consent',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.subscription.entitlements.index',
      method: 'GET',
      pathTemplate: '/subscription/entitlements',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.subscription.products.index',
      method: 'GET',
      pathTemplate: '/subscription/products',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.subscription.purchases.store',
      method: 'POST',
      pathTemplate: '/subscription/purchases',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.settings.show',
      method: 'GET',
      pathTemplate: '/privacy/settings',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.settings.update',
      method: 'PUT',
      pathTemplate: '/privacy/settings',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.contacts.update',
      method: 'PUT',
      pathTemplate: '/privacy/contacts',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.exports.store',
      method: 'POST',
      pathTemplate: '/privacy/exports',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.exports.index',
      method: 'GET',
      pathTemplate: '/privacy/exports',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.exports.download',
      method: 'GET',
      pathTemplate: '/privacy/exports/{export}/download',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.deletion.store',
      method: 'POST',
      pathTemplate: '/privacy/deletion',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.deletion.show',
      method: 'GET',
      pathTemplate: '/privacy/deletion',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.privacy.deletion.destroy',
      method: 'DELETE',
      pathTemplate: '/privacy/deletion',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.support.tickets.index',
      method: 'GET',
      pathTemplate: '/support/tickets',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.support.tickets.store',
      method: 'POST',
      pathTemplate: '/support/tickets',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.support.tickets.show',
      method: 'GET',
      pathTemplate: '/support/tickets/{ticket}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.support.tickets.replies.store',
      method: 'POST',
      pathTemplate: '/support/tickets/{ticket}/replies',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.support.attachments.store',
      method: 'POST',
      pathTemplate: '/support/tickets/{ticket}/attachments',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.support.attachments.show',
      method: 'GET',
      pathTemplate: '/support/attachments/{attachment}',
      requiresBearerToken: true,
    ),
    SoulApiEndpoint(
      operationId: 'api.v1.chat.realtime.show',
      method: 'GET',
      pathTemplate: '/matches/{match}/realtime',
      requiresBearerToken: true,
    ),
  ];

  static final byOperationId = <String, SoulApiEndpoint>{
    for (final endpoint in endpoints) endpoint.operationId: endpoint,
  };
}

abstract final class SoulV1Values {
  static const gender = <String>['man', 'woman'];
  static const religionDiscoveryMode = <String>['my_religion', 'all_religions'];
  static const maritalStatus = <String>['never_married', 'married', 'separated', 'divorced', 'widowed'];
  static const professionStatus = <String>['employed', 'self_employed', 'student', 'homemaker', 'unemployed', 'retired', 'other'];
  static const smokingAlcohol = <String>['no', 'occasionally', 'yes', 'prefer_not_to_say'];
  static const currentChildren = <String>['no', 'yes_living_with_me', 'yes_not_living_with_me', 'prefer_not_to_say'];
  static const futureChildren = <String>['want_children', 'do_not_want_children', 'open_to_children', 'not_sure', 'prefer_not_to_say'];
  static const profileDecision = <String>['like', 'pass'];
  static const devicePlatform = <String>['ios', 'android'];
  static const verificationType = <String>['identity', 'selfie_review'];
  static const reportCategory = <String>['fake_profile', 'scam', 'harassment', 'nudity_sexual_content', 'underage', 'false_marital_status', 'other'];
  static const reportAction = <String>['report_only', 'report_and_block'];
  static const profileLifecycle = <String>['draft', 'submitted', 'automated_checks', 'live'];
}
