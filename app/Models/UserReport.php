<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class UserReport extends Model
{
 protected $fillable=['reporter_user_id','reported_user_id','category','details','status'];
 protected static function booted(): void { static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid()); }
}
