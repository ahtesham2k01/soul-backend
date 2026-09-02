<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class NotificationPreference extends Model {
 protected $fillable=['new_matches','new_messages','safety_updates','marketing'];
 protected function casts(): array { return ['new_matches'=>'boolean','new_messages'=>'boolean','safety_updates'=>'boolean','marketing'=>'boolean']; }
}
