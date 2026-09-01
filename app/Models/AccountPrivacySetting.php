<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class AccountPrivacySetting extends Model {protected $fillable=['show_age','show_city','read_receipts','discoverable'];protected function casts():array{return['show_age'=>'boolean','show_city'=>'boolean','read_receipts'=>'boolean','discoverable'=>'boolean'];}}
