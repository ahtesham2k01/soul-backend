<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class Message extends Model
{
 protected $fillable=['sender_user_id','body','read_at'];
 protected static function booted(): void { static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid()); }
 protected function casts(): array { return ['read_at'=>'immutable_datetime']; }
}
