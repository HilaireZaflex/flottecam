<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id', 'user_id', 'current_truck_id',
        'first_name', 'last_name', 'email', 'phone',
        'license_number', 'license_type', 'license_expiry',
        'date_of_birth', 'address', 'city', 'country',
        'status', 'avatar', 'notes',
    ];

    protected $casts = [
        'license_expiry' => 'date',
        'date_of_birth'  => 'date',
    ];

    protected $appends = ['full_name'];

    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }

    // Status: available, on_mission, on_leave, inactive
    public function company()    { return $this->belongsTo(Company::class); }
    public function user()       { return $this->belongsTo(User::class); }
    public function truck()      { return $this->belongsTo(Truck::class, 'current_truck_id'); }
    public function transports() { return $this->hasMany(Transport::class); }
    public function documents()  { return $this->morphMany(Document::class, 'documentable'); }

    public function isAvailable(): bool { return $this->status === 'available'; }

    public function getLicenseStatusAttribute(): string
    {
        if (!$this->license_expiry) return 'unknown';
        if ($this->license_expiry->isPast()) return 'expired';
        if ($this->license_expiry->diffInDays(now()) <= 30) return 'expiring_soon';
        return 'valid';
    }
}
