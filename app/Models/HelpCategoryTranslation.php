<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HelpCategoryTranslation extends Model
{
    protected $fillable = ['locale', 'name', 'description'];

    public function category(): BelongsTo
    {
        return $this->belongsTo(HelpCategory::class);
    }
}
