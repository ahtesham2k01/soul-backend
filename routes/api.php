<?php

use App\Http\Controllers\Api\V1\AppBootstrapController;
use App\Http\Controllers\Api\V1\Admin\ModerationController;
use App\Http\Controllers\Api\V1\Admin\AdminAuditLogController;
use App\Http\Controllers\Api\V1\Admin\AdminAccountController;
use App\Http\Controllers\Api\V1\Admin\ReligionTaxonomyController;
use App\Http\Controllers\Api\V1\Admin\AdminUserController;
use App\Http\Controllers\Api\V1\Auth\AppleSignInController;
use App\Http\Controllers\Api\V1\Auth\CurrentUserController;
use App\Http\Controllers\Api\V1\Auth\GoogleSignInController;
use App\Http\Controllers\Api\V1\Auth\LoginRequestOtpController;
use App\Http\Controllers\Api\V1\Auth\LoginVerifyOtpController;
use App\Http\Controllers\Api\V1\Auth\LogoutAllDevicesController;
use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\RegisterRequestOtpController;
use App\Http\Controllers\Api\V1\Auth\RegisterVerifyOtpController;
use App\Http\Controllers\Api\V1\Discovery\DiscoveryPreferenceController;
use App\Http\Controllers\Api\V1\Discovery\ListCandidatesController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\Matching\ListMatchesController;
use App\Http\Controllers\Api\V1\Matching\StoreProfileDecisionController;
use App\Http\Controllers\Api\V1\Matching\UnmatchController;
use App\Http\Controllers\Api\V1\Messaging\MatchMessagesController;
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
use App\Http\Controllers\Api\V1\ReadinessController;
use App\Http\Controllers\Api\V1\ResolveLocationController;
use App\Http\Controllers\Api\V1\Safety\BlockUserController;
use App\Http\Controllers\Api\V1\Safety\ReportUserController;
use App\Http\Controllers\Api\V1\Safety\ProfileVerificationController;
use App\Http\Controllers\Api\V1\Safety\SubmitVerificationAppealController;
use App\Http\Controllers\Api\V1\Webhooks\CloudinaryModerationController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::prefix('admin')->middleware(['auth:sanctum', 'active.account', 'admin:super_admin,moderator'])->group(function (): void {
        Route::get('/dashboard', [ModerationController::class, 'dashboard'])->name('api.v1.admin.dashboard');
        Route::get('/reports', [ModerationController::class, 'reports'])->name('api.v1.admin.reports.index');
        Route::put('/reports/{report}', [ModerationController::class, 'decideReport'])->name('api.v1.admin.reports.update');
        Route::get('/verifications', [ModerationController::class, 'verifications'])->name('api.v1.admin.verifications.index');
        Route::put('/verifications/{case}', [ModerationController::class, 'decideVerification'])->name('api.v1.admin.verifications.update');
        Route::get('/users', [AdminUserController::class, 'index'])->name('api.v1.admin.users.index');
        Route::get('/users/{user}', [AdminUserController::class, 'show'])->name('api.v1.admin.users.show');
        Route::put('/users/{user}/status', [AdminUserController::class, 'updateStatus'])
            ->middleware('admin:super_admin')->name('api.v1.admin.users.status.update');
        Route::get('/audit-logs', AdminAuditLogController::class)->name('api.v1.admin.audit-logs.index');
        Route::middleware('admin:super_admin')->group(function (): void {
            Route::get('/admins', [AdminAccountController::class, 'index'])->name('api.v1.admin.admins.index');
            Route::post('/admins', [AdminAccountController::class, 'store'])->name('api.v1.admin.admins.store');
            Route::put('/admins/{admin}/role', [AdminAccountController::class, 'updateRole'])->name('api.v1.admin.admins.role.update');
            Route::delete('/admins/{admin}', [AdminAccountController::class, 'destroy'])->name('api.v1.admin.admins.destroy');
            Route::get('/religion-taxonomy', [ReligionTaxonomyController::class, 'index'])->name('api.v1.admin.religion-taxonomy.index');
            Route::post('/religion-taxonomy', [ReligionTaxonomyController::class, 'store'])->name('api.v1.admin.religion-taxonomy.store');
            Route::put('/religion-taxonomy/{node}', [ReligionTaxonomyController::class, 'update'])->name('api.v1.admin.religion-taxonomy.update');
        });
    });
    Route::middleware(['auth:sanctum', 'active.account'])->group(function (): void {
        Route::get('/discovery/preferences', [DiscoveryPreferenceController::class, 'show'])
            ->name('api.v1.discovery.preferences.show');
        Route::put('/discovery/preferences', [DiscoveryPreferenceController::class, 'update'])
            ->middleware('throttle:30,1')
            ->name('api.v1.discovery.preferences.update');
        Route::get('/discovery/candidates', ListCandidatesController::class)
            ->middleware('throttle:60,1')
            ->name('api.v1.discovery.candidates.index');
        Route::post('/profiles/{profile}/decision', StoreProfileDecisionController::class)
            ->middleware('throttle:120,1')->name('api.v1.matching.decisions.store');
        Route::get('/matches', ListMatchesController::class)
            ->middleware('throttle:60,1')->name('api.v1.matches.index');
        Route::delete('/matches/{match}', UnmatchController::class)
            ->middleware('throttle:30,1')->name('api.v1.matches.destroy');
        Route::get('/matches/{match}/messages', [MatchMessagesController::class, 'index'])
            ->middleware('throttle:120,1')->name('api.v1.messages.index');
        Route::post('/matches/{match}/messages', [MatchMessagesController::class, 'store'])
            ->middleware('throttle:60,1')->name('api.v1.messages.store');
        Route::post('/profiles/{profile}/block', BlockUserController::class)
            ->middleware('throttle:20,1')->name('api.v1.safety.blocks.store');
        Route::post('/profiles/{profile}/report', ReportUserController::class)
            ->middleware('throttle:10,1')->name('api.v1.safety.reports.store');
        Route::get('/verification/cases', [ProfileVerificationController::class, 'index'])
            ->middleware('throttle:60,1')->name('api.v1.verification.cases.index');
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
        Route::get('/privacy/settings', [PrivacyController::class, 'showSettings'])->name('api.v1.privacy.settings.show');
        Route::put('/privacy/settings', [PrivacyController::class, 'updateSettings'])->name('api.v1.privacy.settings.update');
        Route::post('/privacy/exports', [PrivacyController::class, 'requestExport'])->middleware('throttle:2,60')->name('api.v1.privacy.exports.store');
        Route::get('/privacy/exports', [PrivacyController::class, 'exports'])->name('api.v1.privacy.exports.index');
        Route::get('/privacy/exports/{export}/download', [PrivacyController::class, 'download'])->name('api.v1.privacy.exports.download');
        Route::post('/privacy/deletion', [PrivacyController::class, 'scheduleDeletion'])->middleware('throttle:3,60')->name('api.v1.privacy.deletion.store');
    });
    Route::middleware(['auth:sanctum'])->group(function (): void {
        Route::get('/privacy/deletion', [PrivacyController::class, 'deletionStatus'])->name('api.v1.privacy.deletion.show');
        Route::delete('/privacy/deletion', [PrivacyController::class, 'cancelDeletion'])->name('api.v1.privacy.deletion.destroy');
    });
    Route::get(
        '/health',
        HealthController::class,
    )->name('api.v1.health');

    Route::get(
        '/health/ready',
        ReadinessController::class,
    )->name('api.v1.health.ready');

    Route::get(
        '/bootstrap',
        AppBootstrapController::class,
    )->name('api.v1.bootstrap');

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
