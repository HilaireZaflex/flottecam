<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transports', function (Blueprint $table) {
            $table->decimal('montant_transport', 15, 2)->nullable()->after('toll_cost');
            $table->enum('statut_paiement', ['non_paye', 'paye', 'partiel'])->default('non_paye')->after('montant_transport');
            $table->decimal('montant_paye', 15, 2)->default(0)->after('statut_paiement');
        });
    }

    public function down(): void
    {
        Schema::table('transports', function (Blueprint $table) {
            $table->dropColumn(['montant_transport', 'statut_paiement', 'montant_paye']);
        });
    }
};
