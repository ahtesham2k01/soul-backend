<?php

namespace App\Support\Accounts;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class SafeAccountMerger
{
    public function assessment(User $primary, User $duplicate): array
    {
        $blockers = [];
        if ($primary->admin_role !== null || $duplicate->admin_role !== null) {
            $blockers[] = 'admin_account';
        }
        if ($duplicate->profile()->exists()) {
            $blockers[] = 'duplicate_has_profile';
        }
        if ($this->hasInteractions($duplicate)) {
            $blockers[] = 'duplicate_has_member_activity';
        }
        $primaryProviders = $primary->socialAccounts()->pluck('provider')->all();
        if ($duplicate->socialAccounts()->whereIn('provider', $primaryProviders)->exists()) {
            $blockers[] = 'social_provider_conflict';
        }
        if ($duplicate->deletionRequests()->where('status', 'scheduled')->exists()) {
            $blockers[] = 'scheduled_deletion';
        }

        return ['safe_to_merge' => $blockers === [], 'blockers' => $blockers];
    }

    public function merge(User $primary, User $duplicate): void
    {
        $assessment = $this->assessment($primary, $duplicate);
        if (! $assessment['safe_to_merge']) {
            throw new \DomainException('Unsafe account merge.');
        }
        DB::transaction(function () use ($primary, $duplicate): void {
            $email = $duplicate->email;
            $emailVerifiedAt = $duplicate->email_verified_at;
            $phone = $duplicate->phone;
            $phoneVerifiedAt = $duplicate->phone_verified_at;
            $duplicate->socialAccounts()->update(['user_id' => $primary->id]);
            $duplicate->supportTickets()->update(['user_id' => $primary->id]);
            $duplicate->tokens()->delete();
            $duplicate->devices()->update(['revoked_at' => now()]);
            $duplicate->forceFill(['email' => null, 'phone' => null, 'phone_lookup_hash' => null, 'status' => 'merged', 'merged_into_user_id' => $primary->id, 'merged_at' => now()])->save();
            if (! $primary->email && $email) {
                $primary->forceFill(['email' => $email, 'email_verified_at' => $emailVerifiedAt])->save();
            }
            if (! $primary->phone && $phone) {
                $primary->forceFill(['phone' => $phone, 'phone_verified_at' => $phoneVerifiedAt])->save();
            }
        });
    }

    private function hasInteractions(User $user): bool
    {
        return DB::table('user_matches')->where('first_user_id', $user->id)->orWhere('second_user_id', $user->id)->exists()
            || DB::table('profile_decisions')->where('actor_user_id', $user->id)->orWhere('target_user_id', $user->id)->exists()
            || DB::table('user_reports')->where('reporter_user_id', $user->id)->orWhere('reported_user_id', $user->id)->exists();
    }
}
