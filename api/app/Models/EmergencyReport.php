<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmergencyReport extends Model
{
    protected $fillable = [
        'user_id',
        'report_code',
        'incident_type',
        'description',
        'latitude',
        'longitude',
        'address',
        'status',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
