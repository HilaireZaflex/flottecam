<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transport extends Model
{
    use HasFactory;

    protected $fillable = [
        'montant_transport', 'statut_paiement', 'montant_paye',
        'company_id', 'truck_id', 'driver_id', 'reference',
        'origin', 'origin_lat', 'origin_lng',
        'destination', 'destination_lat', 'destination_lng',
        'cargo_type', 'cargo_weight', 'cargo_description',
        'status', 'priority',
        'scheduled_departure', 'scheduled_arrival',
        'actual_departure', 'actual_arrival',
        'distance_km', 'fuel_consumed', 'toll_cost',
        'client_name', 'client_phone', 'client_email',
        'notes', 'signature',
    ];

    protected $casts = [
        'scheduled_departure' => 'datetime',
        'scheduled_arrival'   => 'datetime',
        'actual_departure'    => 'datetime',
        'actual_arrival'      => 'datetime',
        'cargo_weight'        => 'float',
        'distance_km'         => 'float',
        'fuel_consumed'       => 'float',
        'toll_cost'           => 'float',
        'origin_lat'          => 'float',
        'origin_lng'          => 'float',
        'destination_lat'     => 'float',
        'destination_lng'     => 'float',
    ];

    // Status: pending, in_progress, completed, cancelled, delayed
    public function company()    { return $this->belongsTo(Company::class); }
    public function truck()      { return $this->belongsTo(Truck::class); }
    public function driver()     { return $this->belongsTo(Driver::class); }
    public function operations() { return $this->hasMany(Operation::class); }

    public function getDurationAttribute(): ?string
    {
        if (!$this->actual_departure || !$this->actual_arrival) return null;
        return $this->actual_departure->diffForHumans($this->actual_arrival, true);
    }

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($transport) {
            $transport->reference = 'TR-' . strtoupper(uniqid());
        });
    }
}
