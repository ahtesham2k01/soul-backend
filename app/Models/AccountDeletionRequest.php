<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class AccountDeletionRequest extends Model {protected $fillable=['user_id','status','previous_profile_status','scheduled_for','cancelled_at'];protected static function booted():void{static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid());}protected function casts():array{return['scheduled_for'=>'immutable_datetime','cancelled_at'=>'immutable_datetime'];}}
