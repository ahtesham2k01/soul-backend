<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class UserBlock extends Model { protected $fillable=['blocker_user_id','blocked_user_id','reason']; }
