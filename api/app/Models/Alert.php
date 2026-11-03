<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Alert extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'message',
        'type',
        'severity',
        'affected_area',
        'source',
        'status',
        'published_at',
        'ends_at',
    ];

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
