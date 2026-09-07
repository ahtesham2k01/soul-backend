<?php

namespace App\Support\Legal;

use App\Models\User;
use Illuminate\Http\Request;

class LegalConsent
{
    public const COMMITMENT_KEYS = [
        'legal.commitment.respect',
        'legal.commitment.honesty',
        'legal.commitment.no_abuse',
        'legal.commitment.guidelines',
        'legal.commitment.policies',
    ];

    public function versions(): array
    {
        return [
            'terms' => (string) config('soul.legal.terms_version'),
            'privacy' => (string) config('soul.legal.privacy_version'),
            'community_guidelines' => (string) config('soul.legal.community_guidelines_version'),
            'community_commitment' => (string) config('soul.legal.commitment_version'),
        ];
    }

    public function status(User $user): array
    {
        $accepted = $user->legalAcceptances()->get()->groupBy('document_type');
        $documents = collect($this->versions())->map(function (string $version, string $type) use ($accepted): array {
            $record = $accepted->get($type)?->firstWhere('document_version', $version);

            return ['type' => $type, 'current_version' => $version, 'accepted' => $record !== null, 'accepted_at' => $record?->accepted_at?->toIso8601String()];
        })->values()->all();

        return ['requires_acceptance' => collect($documents)->contains('accepted', false), 'documents' => $documents, 'commitment_keys' => self::COMMITMENT_KEYS];
    }

    public function record(User $user, Request $request, array $versions, string $via): void
    {
        $context = trim((string) $request->userAgent().'|'.($request->input('device_id') ?? ''));
        foreach ($versions as $type => $version) {
            $user->legalAcceptances()->firstOrCreate(
                ['document_type' => $type, 'document_version' => $version],
                ['accepted_at' => now(), 'accepted_via' => $via, 'locale' => $user->preferred_locale, 'ip_address' => $request->ip(), 'device_context_hash' => $context === '' ? null : hash('sha256', $context)],
            );
        }
    }
}
