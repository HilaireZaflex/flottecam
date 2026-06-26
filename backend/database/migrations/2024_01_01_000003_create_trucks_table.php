<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trucks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->onDelete('cascade');
            $table->string('plate_number')->unique();
            $table->string('brand');
            $table->string('model');
            $table->integer('year');
            $table->string('type')->default('flatbed');
            $table->float('capacity')->default(0);
            $table->enum('status', ['available', 'on_mission', 'maintenance', 'out_of_service'])->default('available');
            $table->integer('mileage')->default(0);
            $table->string('fuel_type')->default('diesel');
            $table->string('color')->nullable();
            $table->string('vin')->nullable();
            $table->string('photo')->nullable();
            $table->date('insurance_expiry')->nullable();
            $table->date('technical_control_expiry')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trucks');
    }
};
