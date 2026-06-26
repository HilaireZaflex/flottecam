<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Company extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'email', 'phone', 'address', 'city', 'country',
        'logo', 'tax_number', 'is_active', 'subscription_plan',
        'subscription_expires_at',
    ];

    protected $casts = [
        'is_active'               => 'boolean',
        'subscription_expires_at' => 'datetime',
    ];

    public function users()    { return $this->hasMany(User::class); }
    public function trucks()   { return $this->hasMany(Truck::class); }
    public function drivers()  { return $this->hasMany(Driver::class); }
    public function transports(){ return $this->hasMany(Transport::class); }

    public function isSubscriptionActive(): bool
    {
        return $this->subscription_expires_at && $this->subscription_expires_at->isFuture();
    }
}
