
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('relief_tasks', function (Blueprint $table) {
            $table->id();

            // Petugas yang membuat penugasan
            $table->foreignId('assigned_by')
                ->constrained('users')
                ->restrictOnDelete();

            // Relawan yang menerima tugas
            $table->foreignId('volunteer_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->string('title');
            $table->text('description');
            $table->string('location');
            $table->string('priority')->default('sedang');
            $table->string('status')->default('menunggu');

            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('relief_tasks');
    }
};
