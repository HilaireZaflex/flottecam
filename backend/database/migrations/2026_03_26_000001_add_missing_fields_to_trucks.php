<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('trucks', function (Blueprint $table) {
            if (!Schema::hasColumn('trucks', 'proprietaire'))
                $table->string('proprietaire')->nullable()->after('model');
            if (!Schema::hasColumn('trucks', 'telephone_proprietaire'))
                $table->string('telephone_proprietaire')->nullable()->after('proprietaire');
            if (!Schema::hasColumn('trucks', 'ville_actuelle'))
                $table->string('ville_actuelle')->nullable()->after('telephone_proprietaire');
        });
    }
    public function down(): void {
        Schema::table('trucks', function (Blueprint $table) {
            $table->dropColumn(['proprietaire','telephone_proprietaire','ville_actuelle']);
        });
    }
};
