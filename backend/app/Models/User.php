<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'company_id', 'name', 'email', 'password',
        'role', 'is_active', 'avatar', 'phone',
        'google_id', 'facebook_id',
        'last_login_at', 'email_verified_at',
    ];

    protected $hidden = ['password', 'remember_token', 'google_id', 'facebook_id'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'last_login_at'     => 'datetime',
        'is_active'         => 'boolean',
        'password'          => 'hashed',
    ];

    protected $appends = ['avatar_url'];

    public function getAvatarUrlAttribute(): string
    {
        return $this->avatar
            ?? 'https://ui-avatars.com/api/?name=' . urlencode($this->name) . '&background=random';
    }

    public function company()      { return $this->belongsTo(Company::class); }
    public function driver()       { return $this->hasOne(Driver::class); }
    public function fcmTokens()    { return $this->hasMany(FcmToken::class); }
    public function notifications(){ return $this->hasMany(Notification::class); }

    public function isAdmin(): bool   { return $this->role === 'admin'; }
    public function isManager(): bool { return in_array($this->role, ['admin', 'manager']); }
    public function isDriver(): bool  { return $this->role === 'driver'; }
}
