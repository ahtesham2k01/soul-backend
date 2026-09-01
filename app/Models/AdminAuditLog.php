<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AdminAuditLog extends Model {
 public const UPDATED_AT=null;
 protected $fillable=['admin_user_id','action','subject_type','subject_id','before','after','reason','ip_address'];
 protected function casts(): array { return ['before'=>'array','after'=>'array','created_at'=>'immutable_datetime']; }
}
