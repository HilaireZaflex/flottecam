<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->onDelete('cascade');
            $table->foreignId('truck_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('driver_id')->nullable()->constrained()->onDelete('set null');
            $table->string('reference')->unique();
            $table->string('origin');
            $table->decimal('origin_lat', 10, 7)->nullable();
            $table->decimal('origin_lng', 10, 7)->nullable();
            $table->string('destination');
            $table->decimal('destination_lat', 10, 7)->nullable();
            $table->decimal('destination_lng', 10, 7)->nullable();
            $table->string('cargo_type');
            $table->float('cargo_weight')->nullable();
            $table->text('cargo_description')->nullable();
            $table->enum('status', ['pending', 'in_progress', 'completed', 'cancelled', 'delayed'])->default('pending');
            $table->enum('priority', ['low', 'normal', 'high', 'urgent'])->default('normal');
            $table->timestamp('scheduled_departure')->nullable();
            $table->timestamp('scheduled_arrival')->nullable();
            $table->timestamp('actual_departure')->nullable();
            $table->timestamp('actual_arrival')->nullable();
            $table->float('distance_km')->nullable();
            $table->float('fuel_consumed')->nullable();
            $table->float('toll_cost')->nullable();
            $table->string('client_name')->nullable();
            $table->string('client_phone')->nullable();
            $table->string('client_email')->nullable();
            $table->text('notes')->nullable();
            $table->string('signature')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transports');
    }
};
