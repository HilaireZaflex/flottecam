<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Document extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id', 'documentable_type', 'documentable_id',
        'type', 'name', 'file_path', 'expiry_date', 'notes',
    ];

    protected $casts = [
        'expiry_date' => 'date',
    ];

    protected $appends = ['status'];

    public function documentable()
    {
        return $this->morphTo();
    }

    public function getStatusAttribute(): string
    {
        if (!$this->expiry_date) return 'permanent';
        if ($this->expiry_date->isPast()) return 'expired';
        if ($this->expiry_date->diffInDays(now()) <= 30) return 'expiring_soon';
        return 'valid';
    }
}
