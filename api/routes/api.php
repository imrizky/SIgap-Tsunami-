<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EmergencyReportController;
use App\Http\Controllers\Api\EvacuationPointController;
use App\Http\Controllers\Api\SafetyStatusController;
use App\Http\Controllers\Api\AlertController;
use App\Http\Controllers\Api\ReliefTaskController;
use App\Http\Controllers\Api\AdminController;

// ========================================
// REGISTER DAN LOGIN
// ========================================

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);


// ========================================
// FITUR UNTUK SEMUA PENGGUNA YANG SUDAH LOGIN
// ========================================

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/logout', [AuthController::class, 'logout']);


    // LAPORAN DARURAT / SOS
    Route::post('/emergency-reports', [
        EmergencyReportController::class, 'store'
    ]);

    Route::get('/emergency-reports', [
        EmergencyReportController::class, 'index'
    ]);

    Route::get('/emergency-reports/{emergencyReport}', [
        EmergencyReportController::class, 'show'
    ]);


    // STATUS KESELAMATAN WARGA
    Route::post('/safety-statuses', [
        SafetyStatusController::class, 'store'
    ]);

    Route::get('/safety-statuses', [
        SafetyStatusController::class, 'index'
    ]);

    Route::get('/safety-statuses/{safetyStatus}', [
        SafetyStatusController::class, 'show'
    ]);


    // TITIK EVAKUASI
    Route::get('/evacuation-points', [
        EvacuationPointController::class, 'index'
    ]);

    Route::get('/evacuation-points/{evacuationPoint}', [
        EvacuationPointController::class, 'show'
    ]);


    // INFORMASI PERINGATAN BENCANA
    Route::get('/alerts', [
        AlertController::class, 'index'
    ]);

    Route::get('/alerts/{alert}', [
        AlertController::class, 'show'
    ]);

});


// ========================================
// FITUR KHUSUS PETUGAS
// ========================================

Route::middleware(['auth:sanctum', 'role:petugas'])->group(function () {

    // TES AKSES PETUGAS
    Route::get('/tes-petugas', function (Request $request) {
        return response()->json([
            'message' => 'Akses petugas berhasil!',
            'user' => $request->user()->name,
            'role' => $request->user()->role,
        ]);
    });


    // DASHBOARD PETUGAS
    Route::get('/petugas/dashboard', [
        EmergencyReportController::class, 'dashboard'
    ]);


    // KELOLA LAPORAN DARURAT
    Route::patch('/emergency-reports/{emergencyReport}/status', [
        EmergencyReportController::class, 'updateStatus'
    ]);


    // KELOLA TITIK EVAKUASI
    Route::post('/evacuation-points', [
        EvacuationPointController::class, 'store'
    ]);

    Route::patch('/evacuation-points/{evacuationPoint}', [
        EvacuationPointController::class, 'update'
    ]);

    Route::delete('/evacuation-points/{evacuationPoint}', [
        EvacuationPointController::class, 'destroy'
    ]);


    // KELOLA INFORMASI PERINGATAN BENCANA
    Route::post('/alerts', [
        AlertController::class, 'store'
    ]);

    Route::patch('/alerts/{alert}', [
        AlertController::class, 'update'
    ]);


    // PENUGASAN RELAWAN
    Route::get('/relief-tasks', [
        ReliefTaskController::class, 'index'
    ]);

    Route::post('/relief-tasks', [
        ReliefTaskController::class, 'store'
    ]);

    Route::patch('/relief-tasks/{reliefTask}', [
        ReliefTaskController::class, 'update'
    ]);

});


// ========================================
// FITUR KHUSUS RELAWAN
// ========================================

Route::middleware(['auth:sanctum', 'role:relawan'])->group(function () {

    // RELAWAN MELIHAT TUGAS MILIKNYA SENDIRI
    Route::get('/relawan/tasks', [
        ReliefTaskController::class, 'volunteerIndex'
    ]);

    // RELAWAN MEMPERBARUI STATUS TUGAS MILIKNYA
    Route::patch('/relawan/tasks/{reliefTask}/status', [
        ReliefTaskController::class, 'updateVolunteerStatus'
    ]);

});


// ========================================
// FITUR KHUSUS ADMINISTRATOR
// ========================================

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {

    // RINGKASAN STATISTIK SISTEM
    Route::get('/admin/stats', [
        AdminController::class, 'stats'
    ]);

    // DAFTAR PENGGUNA
    Route::get('/admin/users', [
        AdminController::class, 'users'
    ]);

    // UBAH ROLE PENGGUNA
    Route::patch('/admin/users/{user}/role', [
        AdminController::class, 'updateRole'
    ]);

});
