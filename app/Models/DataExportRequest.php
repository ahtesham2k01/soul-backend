<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
class DataExportRequest extends Model {protected $fillable=['user_id','status','file_path','completed_at','expires_at'];protected static function booted():void{static::creating(fn(self $x)=>$x->public_id??=(string)Str::ulid());}protected function casts():array{return['completed_at'=>'immutable_datetime','expires_at'=>'immutable_datetime'];}}
