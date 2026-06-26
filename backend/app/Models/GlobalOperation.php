<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GlobalOperation extends Model
{
    protected $table = 'global_operations';

    protected $fillable = [
        'company_id', 'truck_id', 'user_id',
        'date', 'designation', 'quantite', 'prix_unitaire',
        'type_operation', 'categorie', 'notes',
    ];

    protected $casts = [
        'date'          => 'date',
        'quantite'      => 'float',
        'prix_unitaire' => 'float',
        'montant'       => 'float',
    ];

    // Relations
    public function company(): BelongsTo { return $this->belongsTo(Company::class); }
    public function truck():   BelongsTo { return $this->belongsTo(Truck::class); }
    public function user():    BelongsTo { return $this->belongsTo(User::class); }

    // Scope company
    public function scopeForCompany($query, int $companyId)
    {
        return $query->where('company_id', $companyId);
    }

    // Scope type
    public function scopeRecettes($query) { return $query->where('type_operation', 'recette'); }
    public function scopeDepenses($query) { return $query->where('type_operation', 'depense'); }
}
