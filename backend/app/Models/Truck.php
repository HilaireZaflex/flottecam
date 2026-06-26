<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Truck extends Model
{
    use HasFactory;

    protected $fillable = [
        'proprietaire', 'telephone_proprietaire', 'ville_actuelle',
        'company_id', 'plate_number', 'brand', 'model', 'year',
        'type', 'capacity', 'status', 'mileage', 'fuel_type',
        'color', 'vin', 'insurance_expiry', 'technical_control_expiry',
        'notes', 'photo',
    ];

    protected $casts = [
        'insurance_expiry'         => 'date',
        'technical_control_expiry' => 'date',
        'capacity'                 => 'float',
        'mileage'                  => 'integer',
        'year'                     => 'integer',
    ];

    // Status: available, on_mission, maintenance, out_of_service
    public function company()    { return $this->belongsTo(Company::class); }
    public function driver()     { return $this->hasOne(Driver::class, 'current_truck_id'); }
    public function transports() { return $this->hasMany(Transport::class); }
    public function documents()  { return $this->morphMany(Document::class, 'documentable'); }

    // Transport actif en cours (in_progress ou pending)
    public function activeTransport()
    {
        return $this->hasOne(Transport::class)
            ->whereIn('status', ['in_progress', 'pending'])
            ->latest('actual_departure')
            ->select([
                'id', 'truck_id', 'status', 'origin', 'destination',
                'actual_departure', 'actual_arrival',
                'scheduled_departure', 'scheduled_arrival',
                'client_name', 'reference',
            ]);
    }

    public function isAvailable(): bool { return $this->status === 'available'; }
    public function isOnMission(): bool { return $this->status === 'on_mission'; }

    public function getInsuranceStatusAttribute(): string
    {
        if (!$this->insurance_expiry) return 'unknown';
        if ($this->insurance_expiry->isPast()) return 'expired';
        if ($this->insurance_expiry->diffInDays(now()) <= 30) return 'expiring_soon';
        return 'valid';
    }
}
