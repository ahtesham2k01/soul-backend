<?php

use App\Http\Controllers\Api\V1\Admin\AccountAppealController as AdminAccountAppealController;
use App\Http\Controllers\Api\V1\Admin\AdminAccountController;
use App\Http\Controllers\Api\V1\Admin\AdminAuditLogController;
use App\Http\Controllers\Api\V1\Admin\AdminUserController;
use App\Http\Controllers\Api\V1\Admin\CatalogController as AdminCatalogController;
use App\Http\Controllers\Api\V1\Admin\DuplicateAccountController as AdminDuplicateAccountController;
use App\Http\Controllers\Api\V1\Admin\EntitlementController as AdminEntitlementController;
use App\Http\Controllers\Api\V1\Admin\EventController as AdminEventController;
use App\Http\Controllers\Api\V1\Admin\ModerationController;
use App\Http\Controllers\Api\V1\Admin\NotificationBroadcastController;
use App\Http\Controllers\Api\V1\Admin\OperationsController as AdminOperationsController;
use App\Http\Controllers\Api\V1\Admin\ProfileCatalogController as AdminProfileCatalogController;
use App\Http\Controllers\Api\V1\Admin\ReligionTaxonomyController;
use App\Http\Controllers\Api\V1\Admin\SupportTicketController as AdminSupportTicketController;
use App\Http\Controllers\Api\V1\AppBootstrapController;
use App\Http\Controllers\Api\V1\Auth\AppleSignInController;
use App\Http\Controllers\Api\V1\Auth\CurrentUserController;
use App\Http\Controllers\Api\V1\Auth\DeviceSessionController;
use App\Http\Controllers\Api\V1\Auth\GoogleSignInController;
use App\Http\Controllers\Api\V1\Auth\LoginRequestOtpController;
use App\Http\Controllers\Api\V1\Auth\LoginVerifyOtpController;
use App\Http\Controllers\Api\V1\Auth\LogoutAllDevicesController;
use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\RegisterRequestOtpController;
use App\Http\Controllers\Api\V1\Auth\RegisterVerifyOtpController;
use App\Http\Controllers\Api\V1\Discovery\DiscoveryPreferenceController;
use App\Http\Controllers\Api\V1\Discovery\ListCandidatesController;
use App\Http\Controllers\Api\V1\Discovery\ShowProfileController;
use App\Http\Controllers\Api\V1\Events\EventController;
use App\Http\Controllers\Api\V1\Events\EventRegistrationController;
use App\Http\Controllers\Api\V1\Events\EventReportController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\Legal\LegalConsentController;
use App\Http\Controllers\Api\V1\Matching\LikeRequestController;
use App\Http\Controllers\Api\V1\Matching\ListMatchesController;
use App\Http\Controllers\Api\V1\Matching\PrivatePhotoAccessController;
use App\Http\Controllers\Api\V1\Matching\StoreProfileDecisionController;
use App\Http\Controllers\Api\V1\Matching\UnmatchController;
use App\Http\Controllers\Api\V1\Messaging\ChatPresenceController;
use App\Http\Controllers\Api\V1\Messaging\MatchMessagesController;
use App\Http\Controllers\Api\V1\Messaging\RealtimeSubscriptionController;
use App\Http\Controllers\Api\V1\Notifications\DeviceController;
use App\Http\Controllers\Api\V1\Notifications\NotificationFeedController;
use App\Http\Controllers\Api\V1\Notifications\PreferenceController;
use App\Http\Controllers\Api\V1\Onboarding\CreateProfilePhotoUploadController;
use App\Http\Controllers\Api\V1\Onboarding\DeleteProfilePhotoController;
use App\Http\Controllers\Api\V1\Onboarding\ListProfilePhotosController;
use App\Http\Controllers\Api\V1\Onboarding\RegisterProfilePhotoController;
use App\Http\Controllers\Api\V1\Onboarding\ReligionOptionsController;
use App\Http\Controllers\Api\V1\Onboarding\ResubmitProfileController;
use App\Http\Controllers\Api\V1\Onboarding\ShowProfileDraftController;
use App\Http\Controllers\Api\V1\Onboarding\ShowProfileStatusController;
use App\Http\Controllers\Api\V1\Onboarding\ShowReadinessController;
use App\Http\Controllers\Api\V1\Onboarding\ShowReligionProfileController;
use App\Http\Controllers\Api\V1\Onboarding\StoreReligionProfileController;
use App\Http\Controllers\Api\V1\Onboarding\SubmitProfileController;
use App\Http\Controllers\Api\V1\Onboarding\UpdateProfileDraftController;
use App\Http\Controllers\Api\V1\Privacy\PrivacyController;
use App\Http\Controllers\Api\V1\ProfileCatalogController;
use App\Http\Controllers\Api\V1\ReadinessController;
use App\Http\Controllers\Api\V1\ResolveLocationController;
use App\Http\Controllers\Api\V1\Safety\AccountAppealController;
use App\Http\Controllers\Api\V1\Safety\BlockUserController;
use App\Http\Controllers\Api\V1\Safety\ProfileVerificationController;
use App\Http\Controllers\Api\V1\Safety\ReportUserController;
use App\Http\Controllers\Api\V1\Safety\SubmitVerificationAppealController;
use App\Http\Controllers\Api\V1\Subscriptions\EntitlementController;
use App\Http\Controllers\Api\V1\Subscriptions\ProductController;
use App\Http\Controllers\Api\V1\Subscriptions\PurchaseController;
use App\Http\Controllers\Api\V1\Webhooks\StoreLifecycleController;
use App\Http\Controllers\Api\V1\SupportAttachmentController;
use App\Http\Controllers\Api\V1\SupportTicketController;
use App\Http\Controllers\Api\V1\Webhooks\CloudinaryModerationController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::prefix('admin')->middleware(['auth:sanctum', 'active.account', 'admin:super_admin,moderator', 'throttle:300,1'])->group(function (): void {
        Route::get('/dashboard', [ModerationController::class, 'dashboard'])->name('api.v1.admin.dashboard');
        Route::get('/reports', [ModerationController::class, 'reports'])->name('api.v1.admin.reports.index');
        Route::put('/reports/{report}', [ModerationController::class, 'decideReport'])->name('api.v1.admin.reports.update');
        Route::get('/safety-cases', [ModerationController::class, 'safetyCases'])->name('api.v1.admin.safety-cases.index');
        Route::put('/safety-cases/{case}', [ModerationController::class, 'decideSafetyCase'])->name('api.v1.admin.safety-cases.update');
        Route::get('/verifications', [ModerationController::class, 'verifications'])->name('api.v1.admin.verifications.index');
        Route::put('/verifications/{case}', [ModerationController::class, 'decideVerification'])->name('api.v1.admin.verifications.update');
        Route::get('/account-appeals', [AdminAccountAppealController::class, 'index'])->name('api.v1.admin.account-appeals.index');
        Route::put('/account-appeals/{appeal}', [AdminAccountAppealController::class, 'update'])
            ->middleware('admin:super_admin')->name('api.v1.admin.account-appeals.update');
        Route::get('/users', [AdminUserController::class, 'index'])->name('api.v1.admin.users.index');
        Route::get('/users/{user}', [AdminUserController::class, 'show'])->name('api.v1.admin.users.show');
        Route::put('/users/{user}/status', [AdminUserController::class, 'updateStatus'])
            ->middleware('admin:super_admin')->name('api.v1.admin.users.status.update');
        Route::get('/audit-logs', AdminAuditLogController::class)->name('api.v1.admin.audit-logs.index');
        Route::get('/support-tickets', [AdminSupportTicketController::class, 'index'])->name('api.v1.admin.support-tickets.index');
        Route::get('/support-tickets/{ticket}', [AdminSupportTicketController::class, 'show'])->name('api.v1.admin.support-tickets.show');
        Route::put('/support-tickets/{ticket}', [AdminSupportTicketController::class, 'update'])->name('api.v1.admin.support-tickets.update');
        Route::middleware('admin:super_admin')->group(function (): void {
            Route::get('/admins', [AdminAccountController::class, 'index'])->name('api.v1.admin.admins.index');
            Route::post('/admins', [AdminAccountController::class, 'store'])->name('api.v1.admin.admins.store');
            Route::put('/admins/{admin}/role', [AdminAccountController::class, 'updateRole'])->name('api.v1.admin.admins.role.update');
            Route::delete('/admins/{admin}', [AdminAccountController::class, 'destroy'])->name('api.v1.admin.admins.destroy');
            Route::get('/religion-taxonomy', [ReligionTaxonomyController::class, 'index'])->name('api.v1.admin.religion-taxonomy.index');
            Route::post('/religion-taxonomy', [ReligionTaxonomyController::class, 'store'])->name('api.v1.admin.religion-taxonomy.store');
            Route::put('/religion-taxonomy/{node}', [ReligionTaxonomyController::class, 'update'])->name('api.v1.admin.religion-taxonomy.update');
            Route::get('/notification-broadcasts', [NotificationBroadcastController::class, 'index'])->name('api.v1.admin.notification-broadcasts.index');
            Route::post('/notification-broadcasts', [NotificationBroadcastController::class, 'store'])->name('api.v1.admin.notification-broadcasts.store');
            Route::post('/notification-broadcasts/{broadcast}/send', [NotificationBroadcastController::class, 'send'])->name('api.v1.admin.notification-broadcasts.send');
            Route::get('/events', [AdminEventController::class, 'index'])->name('api.v1.admin.events.index');
            Route::post('/events', [AdminEventController::class, 'store'])->name('api.v1.admin.events.store');
            Route::put('/events/{event}', [AdminEventController::class, 'update'])->name('api.v1.admin.events.update');
            Route::put('/events/{event}/status', [AdminEventController::class, 'status'])->name('api.v1.admin.events.status.update');
            Route::get('/event-reports', [AdminEventController::class, 'reports'])->name('api.v1.admin.event-reports.index');
            Route::put('/event-reports/{report}', [AdminEventController::class, 'decideReport'])->name('api.v1.admin.event-reports.update');
            Route::get('/entitlements', [AdminEntitlementController::class, 'index'])->name('api.v1.admin.entitlements.index');
            Route::post('/entitlements/features', [AdminEntitlementController::class, 'storeFeature'])->name('api.v1.admin.entitlements.features.store');
            Route::put('/entitlements/features/{feature}', [AdminEntitlementController::class, 'updateFeature'])->name('api.v1.admin.entitlements.features.update');
            Route::put('/entitlements/features/{feature}/countries', [AdminEntitlementController::class, 'countryOverride'])->name('api.v1.admin.entitlements.countries.update');
            Route::put('/entitlements/features/{feature}/platforms', [AdminEntitlementController::class, 'platformOverride'])->name('api.v1.admin.entitlements.platforms.update');
            Route::post('/entitlements/plans', [AdminEntitlementController::class, 'storePlan'])->name('api.v1.admin.entitlements.plans.store');
            Route::put('/entitlements/plans/{plan}', [AdminEntitlementController::class, 'updatePlan'])->name('api.v1.admin.entitlements.plans.update');
            Route::post('/entitlements/products', [AdminEntitlementController::class, 'storeProduct'])->name('api.v1.admin.entitlements.products.store');
            Route::put('/entitlements/products/{product}', [AdminEntitlementController::class, 'updateProduct'])->name('api.v1.admin.entitlements.products.update');
            Route::post('/entitlements/promotions', [AdminEntitlementController::class, 'storePromotion'])->name('api.v1.admin.entitlements.promotions.store');
            Route::put('/entitlements/promotions/{promotion}', [AdminEntitlementController::class, 'updatePromotion'])->name('api.v1.admin.entitlements.promotions.update');
            Route::put('/users/{user}/entitlements', [AdminEntitlementController::class, 'override'])->name('api.v1.admin.entitlements.users.update');
            Route::get('/catalogs', [AdminCatalogController::class, 'index'])->name('api.v1.admin.catalogs.index');
            Route::put('/catalogs/translations', [AdminCatalogController::class, 'updateTranslation'])->name('api.v1.admin.catalogs.translations.update');
            Route::get('/operations', AdminOperationsController::class)->name('api.v1.admin.operations.index');
            Route::get('/duplicate-accounts', [AdminDuplicateAccountController::class, 'index'])->name('api.v1.admin.duplicate-accounts.index');
            Route::post('/duplicate-accounts', [AdminDuplicateAccountController::class, 'store'])->name('api.v1.admin.duplicate-accounts.store');
            Route::put('/duplicate-accounts/{case}', [AdminDuplicateAccountController::class, 'resolve'])->name('api.v1.admin.duplicate-accounts.resolve');
            Route::get('/profile-catalogs', [AdminProfileCatalogController::class, 'index'])->name('api.v1.admin.profile-catalogs.index');
            Route::post('/profile-catalogs/items', [AdminProfileCatalogController::class, 'storeProfileItem'])->name('api.v1.admin.profile-catalogs.items.store');
            Route::put('/profile-catalogs/items/{item}', [AdminProfileCatalogController::class, 'updateProfileItem'])->name('api.v1.admin.profile-catalogs.items.update');
            Route::post('/profile-catalogs/help-categories', [AdminProfileCatalogController::class, 'storeHelpCategory'])->name('api.v1.admin.profile-catalogs.help-categories.store');
            Route::put('/profile-catalogs/help-categories/{category}', [AdminProfileCatalogController::class, 'updateHelpCategory'])->name('api.v1.admin.profile-catalogs.help-categories.update');
        });
    });
    Route::middleware(['auth:sanctum', 'active.account', 'record.activity', 'throttle:300,1'])->group(function (): void {
        Route::get('/discovery/preferences', [DiscoveryPreferenceController::class, 'show'])
            ->name('api.v1.discovery.preferences.show');
        Route::put('/discovery/preferences', [DiscoveryPreferenceController::class, 'update'])
            ->middleware('throttle:30,1')
            ->name('api.v1.discovery.preferences.update');
        Route::get('/discovery/candidates', ListCandidatesController::class)
            ->middleware('throttle:60,1')
            ->name('api.v1.discovery.candidates.index');
        Route::get('/profiles/{profile}', ShowProfileController::class)
            ->middleware('throttle:120,1')->name('api.v1.profiles.show');
        Route::post('/profiles/{profile}/decision', StoreProfileDecisionController::class)
            ->middleware('throttle:120,1')->name('api.v1.matching.decisions.store');
        Route::get('/likes/received', [LikeRequestController::class, 'index'])
            ->middleware('throttle:60,1')->name('api.v1.likes.received.index');
        Route::put('/profiles/{profile}/like', [LikeRequestController::class, 'respond'])
            ->middleware('throttle:60,1')->name('api.v1.likes.update');
        Route::delete('/profiles/{profile}/like', [LikeRequestController::class, 'withdraw'])
            ->middleware('throttle:60,1')->name('api.v1.likes.destroy');
        Route::get('/matches', ListMatchesController::class)
            ->middleware('throttle:60,1')->name('api.v1.matches.index');
        Route::delete('/matches/{match}', UnmatchController::class)
            ->middleware('throttle:30,1')->name('api.v1.matches.destroy');
        Route::get('/private-photo-access', [PrivatePhotoAccessController::class, 'index'])
            ->middleware('throttle:60,1')->name('api.v1.private-photo-access.index');
        Route::post('/matches/{match}/private-photo-access', [PrivatePhotoAccessController::class, 'store'])
            ->middleware('throttle:20,1')->name('api.v1.private-photo-access.store');
        Route::put('/private-photo-access/{accessRequest}', [PrivatePhotoAccessController::class, 'decide'])
            ->middleware('throttle:20,1')->name('api.v1.private-photo-access.update');
        Route::delete('/private-photo-access/{accessRequest}', [PrivatePhotoAccessController::class, 'destroy'])
            ->middleware('throttle:20,1')->name('api.v1.private-photo-access.destroy');
        Route::get('/matches/{match}/private-photos', [PrivatePhotoAccessController::class, 'photos'])
            ->middleware('throttle:60,1')->name('api.v1.private-photos.index');
        Route::get('/private-photos/{photo}/content', [PrivatePhotoAccessController::class, 'content'])
            ->middleware('throttle:120,1')->name('api.v1.private-photos.content');
        Route::post('/private-photos/{photo}/capture-events', [PrivatePhotoAccessController::class, 'capture'])
            ->middleware('throttle:30,1')->name('api.v1.private-photos.capture-events.store');
        Route::get('/matches/{match}/messages', [MatchMessagesController::class, 'index'])
            ->middleware('throttle:120,1')->name('api.v1.messages.index');
        Route::post('/matches/{match}/messages', [MatchMessagesController::class, 'store'])
            ->middleware('throttle:60,1')->name('api.v1.messages.store');
        Route::post('/matches/{match}/messages/read', [MatchMessagesController::class, 'read'])
            ->middleware('throttle:120,1')->name('api.v1.messages.read');
        Route::get('/matches/{match}/presence', [ChatPresenceController::class, 'show'])
            ->middleware('throttle:120,1')->name('api.v1.chat.presence.show');
        Route::put('/matches/{match}/typing', [ChatPresenceController::class, 'typing'])
            ->middleware('throttle:120,1')->name('api.v1.chat.typing.update');
        Route::get('/matches/{match}/realtime', RealtimeSubscriptionController::class)
            ->middleware('throttle:60,1')->name('api.v1.chat.realtime.show');
        Route::post('/profiles/{profile}/block', BlockUserController::class)
            ->middleware('throttle:20,1')->name('api.v1.safety.blocks.store');
        Route::post('/profiles/{profile}/report', ReportUserController::class)
            ->middleware('throttle:10,1')->name('api.v1.safety.reports.store');
        Route::get('/verification/cases', [ProfileVerificationController::class, 'index'])
            ->middleware('throttle:60,1')->name('api.v1.verification.cases.index');
        Route::get('/verification/summary', [ProfileVerificationController::class, 'summary'])
            ->middleware('throttle:60,1')->name('api.v1.verification.summary');
        Route::post('/verification/cases', [ProfileVerificationController::class, 'store'])
            ->middleware('throttle:10,1')->name('api.v1.verification.cases.store');
        Route::post('/verification/cases/{case}/appeal', SubmitVerificationAppealController::class)
            ->middleware('throttle:5,1')->name('api.v1.verification.appeals.store');
        Route::post('/devices', [DeviceController::class, 'store'])->middleware('throttle:20,1')->name('api.v1.devices.store');
        Route::delete('/devices/{device}', [DeviceController::class, 'destroy'])->middleware('throttle:20,1')->name('api.v1.devices.destroy');
        Route::get('/notification-preferences', [PreferenceController::class, 'show'])->name('api.v1.notification-preferences.show');
        Route::put('/notification-preferences', [PreferenceController::class, 'update'])->middleware('throttle:30,1')->name('api.v1.notification-preferences.update');
        Route::get('/notifications', [NotificationFeedController::class, 'index'])->name('api.v1.notifications.index');
        Route::post('/notifications/{notification}/read', [NotificationFeedController::class, 'read'])->middleware('throttle:120,1')->name('api.v1.notifications.read');
        Route::get('/events', [EventController::class, 'index'])->name('api.v1.events.index');
        Route::get('/events/{event}', [EventController::class, 'show'])->name('api.v1.events.show');
        Route::post('/events/{event}/registration', [EventRegistrationController::class, 'store'])->middleware('throttle:20,1')->name('api.v1.events.registration.store');
        Route::delete('/events/{event}/registration', [EventRegistrationController::class, 'destroy'])->middleware('throttle:20,1')->name('api.v1.events.registration.destroy');
        Route::post('/events/{event}/report', EventReportController::class)->middleware('throttle:5,60')->name('api.v1.events.reports.store');
        Route::get('/legal/consent', [LegalConsentController::class, 'show'])->name('api.v1.legal.consent.show');
        Route::post('/legal/consent', [LegalConsentController::class, 'store'])->middleware('throttle:10,60')->name('api.v1.legal.consent.store');
        Route::get('/subscription/entitlements', EntitlementController::class)->name('api.v1.subscription.entitlements.index');
        Route::get('/subscription/products', ProductController::class)->name('api.v1.subscription.products.index');
        Route::post('/subscription/purchases', [PurchaseController::class, 'store'])->middleware('throttle:10,1')->name('api.v1.subscription.purchases.store');
        Route::get('/privacy/settings', [PrivacyController::class, 'showSettings'])->name('api.v1.privacy.settings.show');
        Route::put('/privacy/settings', [PrivacyController::class, 'updateSettings'])->name('api.v1.privacy.settings.update');
        Route::put('/privacy/contacts', [PrivacyController::class, 'replaceContacts'])->middleware('throttle:5,60')->name('api.v1.privacy.contacts.update');
        Route::post('/privacy/exports', [PrivacyController::class, 'requestExport'])->middleware('throttle:2,60')->name('api.v1.privacy.exports.store');
        Route::get('/privacy/exports', [PrivacyController::class, 'exports'])->name('api.v1.privacy.exports.index');
        Route::get('/privacy/exports/{export}/download', [PrivacyController::class, 'download'])->name('api.v1.privacy.exports.download');
        Route::post('/privacy/deletion', [PrivacyController::class, 'scheduleDeletion'])->middleware('throttle:3,60')->name('api.v1.privacy.deletion.store');
        Route::get('/support/tickets', [SupportTicketController::class, 'index'])->name('api.v1.support.tickets.index');
        Route::post('/support/tickets', [SupportTicketController::class, 'store'])->middleware('throttle:5,60')->name('api.v1.support.tickets.store');
        Route::get('/support/tickets/{ticket}', [SupportTicketController::class, 'show'])->name('api.v1.support.tickets.show');
        Route::post('/support/tickets/{ticket}/replies', [SupportTicketController::class, 'reply'])->middleware('throttle:20,60')->name('api.v1.support.tickets.replies.store');
        Route::post('/support/tickets/{ticket}/attachments', [SupportAttachmentController::class, 'store'])->middleware('throttle:10,60')->name('api.v1.support.attachments.store');
        Route::get('/support/attachments/{attachment}', [SupportAttachmentController::class, 'show'])->name('api.v1.support.attachments.show');
    });
    Route::middleware(['auth:sanctum'])->group(function (): void {
        Route::get('/privacy/deletion', [PrivacyController::class, 'deletionStatus'])->name('api.v1.privacy.deletion.show');
        Route::delete('/privacy/deletion', [PrivacyController::class, 'cancelDeletion'])->name('api.v1.privacy.deletion.destroy');
        Route::get('/account-appeal', [AccountAppealController::class, 'show'])
            ->middleware('throttle:30,1')->name('api.v1.account-appeal.show');
        Route::post('/account-appeal', [AccountAppealController::class, 'store'])
            ->middleware('throttle:3,60')->name('api.v1.account-appeal.store');
    });
    Route::get(
        '/health',
        HealthController::class,
    )->name('api.v1.health');

    Route::get(
        '/health/ready',
        ReadinessController::class,
    )->name('api.v1.health.ready');

    Route::post('/webhooks/stores/{platform}', StoreLifecycleController::class)
        ->middleware('throttle:120,1')->name('api.v1.webhooks.stores');

    Route::get(
        '/bootstrap',
        AppBootstrapController::class,
    )->name('api.v1.bootstrap');

    Route::get('/catalogs/profile', ProfileCatalogController::class)
        ->middleware('throttle:60,1')->name('api.v1.catalogs.profile');

    Route::post(
        '/auth/register/request-otp',
        RegisterRequestOtpController::class,
    )
        ->middleware('throttle:email-otp-request')
        ->name('api.v1.auth.register.request-otp');

    Route::post(
        '/auth/register/verify-otp',
        RegisterVerifyOtpController::class,
    )
        ->middleware('throttle:email-otp-verification')
        ->name('api.v1.auth.register.verify-otp');

    Route::post(
        '/auth/login/request-otp',
        LoginRequestOtpController::class,
    )
        ->middleware('throttle:email-otp-request')
        ->name('api.v1.auth.login.request-otp');

    Route::post(
        '/auth/login/verify-otp',
        LoginVerifyOtpController::class,
    )
        ->middleware('throttle:email-otp-verification')
        ->name('api.v1.auth.login.verify-otp');

    Route::post(
        '/auth/google',
        GoogleSignInController::class,
    )
        ->middleware('throttle:social-sign-in')
        ->name('api.v1.auth.google');
    Route::post(
        '/auth/apple',
        AppleSignInController::class,
    )
        ->middleware('throttle:social-sign-in')
        ->name('api.v1.auth.apple');
    Route::middleware([
        'auth:sanctum',
        'active.account',
    ])
        ->prefix('auth')
        ->group(function (): void {
            Route::get(
                '/me',
                CurrentUserController::class,
            )->name('api.v1.auth.me');

            Route::post(
                '/logout',
                LogoutController::class,
            )->name('api.v1.auth.logout');

            Route::post(
                '/logout-all',
                LogoutAllDevicesController::class,
            )->name('api.v1.auth.logout-all');

            Route::get('/devices', [DeviceSessionController::class, 'index'])
                ->middleware('throttle:60,1')
                ->name('api.v1.auth.devices.index');

            Route::delete('/devices/{session}', [DeviceSessionController::class, 'destroy'])
                ->middleware('throttle:20,1')
                ->name('api.v1.auth.devices.destroy');
        });

    Route::post(
        '/location/resolve',
        ResolveLocationController::class,
    )
        ->middleware('throttle:location-resolution')
        ->name('api.v1.location.resolve');

    Route::post(
        '/webhooks/cloudinary/moderation',
        CloudinaryModerationController::class,
    )
        ->middleware('throttle:120,1')
        ->name('api.v1.webhooks.cloudinary.moderation');

    Route::get(
        '/onboarding/religion-options',
        ReligionOptionsController::class,
    )
        ->middleware('throttle:60,1')
        ->name('api.v1.onboarding.religion-options');

    Route::put(
        '/onboarding/religion-profile',
        StoreReligionProfileController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:30,1',
        ])
        ->name('api.v1.onboarding.religion-profile.store');

    Route::get(
        '/onboarding/religion-profile',
        ShowReligionProfileController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:60,1',
        ])
        ->name('api.v1.onboarding.religion-profile.show');

    Route::get(
        '/onboarding/profile',
        ShowProfileDraftController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:60,1',
        ])
        ->name('api.v1.onboarding.profile.show');

    Route::put(
        '/onboarding/profile',
        UpdateProfileDraftController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:30,1',
        ])
        ->name('api.v1.onboarding.profile.update');

    Route::get(
        '/onboarding/readiness',
        ShowReadinessController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:60,1',
        ])
        ->name('api.v1.onboarding.readiness.show');

    Route::post(
        '/onboarding/submit',
        SubmitProfileController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:10,1',
        ])
        ->name('api.v1.onboarding.submit');

    Route::get(
        '/onboarding/status',
        ShowProfileStatusController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:60,1',
        ])
        ->name('api.v1.onboarding.status');

    Route::post(
        '/onboarding/resubmit',
        ResubmitProfileController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:10,1',
        ])
        ->name('api.v1.onboarding.resubmit');

    Route::get(
        '/onboarding/photos',
        ListProfilePhotosController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:60,1',
        ])
        ->name('api.v1.onboarding.photos.index');

    Route::post(
        '/onboarding/photos/upload-session',
        CreateProfilePhotoUploadController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:20,1',
        ])
        ->name('api.v1.onboarding.photos.upload-session.create');

    Route::put(
        '/onboarding/photos/{position}',
        RegisterProfilePhotoController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:20,1',
        ])
        ->name('api.v1.onboarding.photos.register');

    Route::delete(
        '/onboarding/photos/{position}',
        DeleteProfilePhotoController::class,
    )
        ->middleware([
            'auth:sanctum',
            'active.account',
            'throttle:20,1',
        ])
        ->name('api.v1.onboarding.photos.delete');

    Route::fallback(
        fn () => ApiResponse::error(
            code: 'route_not_found',
            message: 'The requested API endpoint does not exist.',
            status: 404,
        ),
    );
});
