<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('gps_locations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('truck_id')->constrained('trucks')->onDelete('cascade');
            $table->foreignId('driver_id')->nullable()->constrained('drivers')->onDelete('set null');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->decimal('speed', 5, 2)->nullable()->comment('km/h');
            $table->decimal('heading', 5, 2)->nullable()->comment('degrees 0-360');
            $table->decimal('accuracy', 8, 2)->nullable()->comment('meters');
            $table->decimal('altitude', 8, 2)->nullable();
            $table->string('address')->nullable()->comment('reverse geocoded address');
            $table->string('status')->default('moving')->comment('moving/stopped/idle');
            $table->boolean('is_latest')->default(true);
            $table->timestamp('recorded_at');
            $table->timestamps();
            $table->index(['truck_id', 'is_latest']);
            $table->index('recorded_at');
        });
    }

    public function down(): void {
        Schema::dropIfExists('gps_locations');
    }
};
