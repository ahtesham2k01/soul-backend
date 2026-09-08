<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class NotificationBroadcast extends Model {
 protected $fillable=['created_by_admin_id','title','body','category','audience_type','audience_value','status','estimated_recipients','delivered_count','read_count','sent_at','completed_at'];
 protected static function booted(): void { static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid()); }
 public function getRouteKeyName(): string { return 'public_id'; }
 protected function casts(): array { return ['estimated_recipients'=>'integer','delivered_count'=>'integer','read_count'=>'integer','sent_at'=>'immutable_datetime','completed_at'=>'immutable_datetime']; }
}
