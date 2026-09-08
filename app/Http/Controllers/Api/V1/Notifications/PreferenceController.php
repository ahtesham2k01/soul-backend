<?php

namespace App\Http\Controllers\Api\V1\Notifications;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PreferenceController extends Controller
{
    public function show(Request $r): JsonResponse
    {
        return ApiResponse::success(['preferences' => $this->serialize($r->user()->notificationPreference()->firstOrCreate([])->refresh())]);
    }

    public function update(Request $r): JsonResponse
    {
        $v = $r->validate([
            'new_matches' => ['sometimes', 'boolean'], 'new_messages' => ['sometimes', 'boolean'], 'safety_updates' => ['sometimes', 'accepted'], 'marketing' => ['sometimes', 'boolean'],
            'push' => ['sometimes', 'array'], 'push.new_matches' => ['sometimes', 'boolean'], 'push.new_messages' => ['sometimes', 'boolean'], 'push.private_photos' => ['sometimes', 'boolean'], 'push.verification' => ['sometimes', 'boolean'], 'push.account' => ['sometimes', 'boolean'], 'push.marketing' => ['sometimes', 'boolean'], 'push.safety' => ['sometimes', 'accepted'],
            'email' => ['sometimes', 'array'], 'email.new_matches' => ['sometimes', 'boolean'], 'email.new_messages' => ['sometimes', 'boolean'], 'email.private_photos' => ['sometimes', 'boolean'], 'email.verification' => ['sometimes', 'boolean'], 'email.account' => ['sometimes', 'boolean'], 'email.marketing' => ['sometimes', 'boolean'], 'email.safety' => ['sometimes', 'accepted'],
        ]);
        $p = $r->user()->notificationPreference()->firstOrCreate([])->refresh();
        $updates = array_filter([
            'new_matches' => $v['push']['new_matches'] ?? $v['new_matches'] ?? null, 'new_messages' => $v['push']['new_messages'] ?? $v['new_messages'] ?? null,
            'push_private_photos' => $v['push']['private_photos'] ?? null, 'push_verification' => $v['push']['verification'] ?? null, 'push_account' => $v['push']['account'] ?? null,
            'push_marketing' => $v['push']['marketing'] ?? $v['marketing'] ?? null, 'marketing' => $v['push']['marketing'] ?? $v['marketing'] ?? null,
            'email_new_matches' => $v['email']['new_matches'] ?? null, 'email_new_messages' => $v['email']['new_messages'] ?? null, 'email_private_photos' => $v['email']['private_photos'] ?? null,
            'email_verification' => $v['email']['verification'] ?? null, 'email_account' => $v['email']['account'] ?? null, 'email_marketing' => $v['email']['marketing'] ?? null,
        ], fn ($x) => $x !== null);
        if (($updates['push_marketing'] ?? false) || ($updates['email_marketing'] ?? false)) {
            $updates['marketing_consented_at'] = $p->marketing_consented_at ?? now();
        }
        $p->update($updates);

        return ApiResponse::success(['preferences' => $this->serialize($p->fresh())]);
    }

    private function serialize($p): array
    {
        $push = ['new_matches' => $p->new_matches, 'new_messages' => $p->new_messages, 'private_photos' => $p->push_private_photos, 'verification' => $p->push_verification, 'account' => $p->push_account, 'marketing' => $p->push_marketing, 'safety' => true];
        $email = ['new_matches' => $p->email_new_matches, 'new_messages' => $p->email_new_messages, 'private_photos' => $p->email_private_photos, 'verification' => $p->email_verification, 'account' => $p->email_account, 'marketing' => $p->email_marketing, 'safety' => true];

        return ['push' => $push, 'email' => $email, 'locked_categories' => ['safety'], 'marketing_consented_at' => $p->marketing_consented_at?->toIso8601String(), 'new_matches' => $p->new_matches, 'new_messages' => $p->new_messages, 'safety_updates' => true, 'marketing' => $p->push_marketing];
    }
}
