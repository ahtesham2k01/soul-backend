<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;
class AdminAuditLog extends Model {
 public const UPDATED_AT=null;
 protected $fillable=['admin_user_id','action','subject_type','subject_id','before','after','reason','ip_address'];
 public function adminUser(): BelongsTo { return $this->belongsTo(User::class, 'admin_user_id'); }
 protected static function booted(): void { static::creating(fn (self $log) => $log->public_id ??= (string) Str::ulid()); }
 protected function casts(): array { return ['before'=>'array','after'=>'array','created_at'=>'immutable_datetime']; }
}
