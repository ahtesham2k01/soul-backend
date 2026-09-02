<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class UserDevice extends Model {
 protected $fillable=['platform','push_token','token_hash','device_name','last_seen_at','revoked_at'];
 protected $hidden=['id','user_id','push_token','token_hash'];
 protected static function booted(): void { static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid()); }
 protected function casts(): array { return ['push_token'=>'encrypted','last_seen_at'=>'immutable_datetime','revoked_at'=>'immutable_datetime']; }
}
