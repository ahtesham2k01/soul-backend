<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;
class Conversation extends Model
{
 protected $fillable=['user_match_id','last_message_at'];
 public function match(): BelongsTo { return $this->belongsTo(UserMatch::class,'user_match_id'); }
 public function messages(): HasMany { return $this->hasMany(Message::class); }
 protected static function booted(): void { static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid()); }
 protected function casts(): array { return ['last_message_at'=>'immutable_datetime']; }
}
