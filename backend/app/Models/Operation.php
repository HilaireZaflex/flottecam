<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Operation extends Model
{
    use HasFactory;

    protected $fillable = [
        'transport_id', 'user_id', 'type', 'description',
        'location', 'lat', 'lng', 'attachments', 'metadata',
    ];

    protected $casts = [
        'attachments' => 'array',
        'metadata'    => 'array',
        'lat'         => 'float',
        'lng'         => 'float',
    ];

    // Types: departure, arrival, stop, fuel, incident, delivery, pickup
    public function transport() { return $this->belongsTo(Transport::class); }
    public function user()      { return $this->belongsTo(User::class); }
}
