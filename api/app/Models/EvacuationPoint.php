<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EvacuationPoint extends Model
{
    protected $fillable = [
        'name',
        'description',
        'address',
        'latitude',
        'longitude',
        'type',
        'capacity',
        'status',
    ];
}
