<?php

namespace App\Support\Verification;

use App\Models\ProfileVerificationCase;
use App\Models\User;

class VerificationSummary
{
    /** @return array<string, array<string, bool|string|null>> */
    public function for(User $user): array
    {
        $cases = ($user->relationLoaded('verificationCases')
            ? $user->verificationCases
            : ProfileVerificationCase::query()->where('user_id', $user->id)->get())
            ->whereIn('type', ['selfie_review', 'identity'])
            ->sortByDesc('id')
            ->unique('type')
            ->keyBy('type');

        return [
            'email' => $this->accountState($user->email_verified_at !== null),
            'phone' => $this->accountState($user->phone_verified_at !== null),
            'selfie' => $this->caseState($cases->get('selfie_review')),
            'identity_age' => $this->caseState($cases->get('identity')),
        ];
    }

    /** @return array{status: string, verified: bool, requirement: string, blocks_profile: bool} */
    private function accountState(bool $verified): array
    {
        return ['status' => $verified ? 'verified' : 'not_verified', 'verified' => $verified, 'requirement' => 'account', 'blocks_profile' => false];
    }

    /** @return array{status: string, verified: bool, requirement: string, blocks_profile: bool} */
    private function caseState(?ProfileVerificationCase $case): array
    {
        $requirement = $case?->requirement ?? 'optional';
        $status = $case?->status ?? 'not_requested';

        return [
            'status' => $status,
            'verified' => $status === 'approved' && $case?->verified_at !== null,
            'requirement' => $requirement,
            'blocks_profile' => $requirement === 'required' && $status !== 'approved',
        ];
    }
}
