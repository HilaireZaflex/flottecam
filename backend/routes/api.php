<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\TruckController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\Api\TransportController;
use App\Http\Controllers\Api\OperationController;
use App\Http\Controllers\Api\GlobalOperationController;
use App\Http\Controllers\Api\ImportController;
use App\Http\Controllers\Api\DocumentController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\GpsController;

/*
|--------------------------------------------------------------------------
| Fleet SaaS API Routes
|--------------------------------------------------------------------------
*/

// Auth (public)
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login',    [AuthController::class, 'login']);
    Route::post('/social/google',   [AuthController::class, 'loginWithGoogle']);
    Route::post('/social/facebook', [AuthController::class, 'loginWithFacebook']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // Dashboard
    Route::get('/dashboard/stats',               [DashboardController::class, 'stats']);
    Route::get('/dashboard/map',                 [DashboardController::class, 'mapData']);
    Route::get('/dashboard/alerts',              [DashboardController::class, 'alerts']);
    Route::get('/dashboard/chart',               [DashboardController::class, 'chartData']);
    Route::get('/dashboard/rentabilite',         [DashboardController::class, 'rentabilite']);
    Route::get('/dashboard/depenses-categorie',  [DashboardController::class, 'depensesParCategorie']);

    // Reports
    Route::get('/reports/monthly',     [ReportController::class, 'monthlyReport']);
    Route::get('/reports/monthly/pdf', [ReportController::class, 'downloadPdf']);

    // Trucks
    Route::apiResource('trucks', TruckController::class);
    Route::get('/trucks/{truck}/transports', [TruckController::class, 'transports']);
    Route::patch('/trucks/{truck}/status',   [TruckController::class, 'updateStatus']);

    // Drivers
    Route::apiResource('drivers', DriverController::class);
    Route::get('/drivers/{driver}/transports', [DriverController::class, 'transports']);
    Route::patch('/drivers/{driver}/assign',   [DriverController::class, 'assignTruck']);

    // Transports
    Route::apiResource('transports', TransportController::class);
    Route::patch('/transports/{transport}/status',    [TransportController::class, 'updateStatus']);
    Route::patch('/transports/{transport}/paiement',  [TransportController::class, 'updatePaiement']);
    Route::patch('/transports/{transport}/retour',    [TransportController::class, 'confirmRetour']);
    Route::post('/transports/{transport}/operations', [OperationController::class, 'store']);
    Route::get('/transports/{transport}/operations',  [OperationController::class, 'index']);

    // Opérations globales (recettes/dépenses)
    Route::get('/operations/stats/par-camion',        [GlobalOperationController::class, 'statsByTruck']);
    Route::get('/operations/stats/par-categorie',     [GlobalOperationController::class, 'statsByCategorie']);
    Route::get('/operations/clients/dettes',          [GlobalOperationController::class, 'clientDettes']);
    Route::apiResource('operations', GlobalOperationController::class);

    // Documents
    Route::apiResource('documents', DocumentController::class);

    // Notifications
    Route::get('/notifications',              [NotificationController::class, 'index']);
    Route::post('/notifications/read-all',    [NotificationController::class, 'readAll']);
    Route::patch('/notifications/{id}/read',  [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/fcm-token',   [NotificationController::class, 'saveFcmToken']);

    // Import Excel
    Route::post('/import/operations',  [ImportController::class, 'importOperations']);
    Route::get('/import/template',     [ImportController::class, 'downloadTemplate']);

    // Users (admin only)
    Route::middleware('role:admin,manager')->group(function () {
        Route::apiResource('users', UserController::class);
    });

    // Profile
    Route::get('/profile',        [UserController::class, 'profile']);
    Route::put('/profile',        [UserController::class, 'updateProfile']);
    Route::post('/profile/photo', [UserController::class, 'updatePhoto']);

    // GPS Routes
    Route::post('/gps/update', [GpsController::class, 'update']);
    Route::get('/gps/latest', [GpsController::class, 'latest']);
    Route::get('/gps/history/{truckId}', [GpsController::class, 'history']);
    Route::get('/gps/truck/{truckId}', [GpsController::class, 'truckPosition']);
});
