<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GpsLocation;
use App\Models\Truck;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class GpsController extends Controller
{
    /**
     * Store GPS location update from driver app
     */
    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'truck_id' => 'required|exists:trucks,id',
            'driver_id' => 'nullable|exists:drivers,id',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'speed' => 'nullable|numeric|min:0',
            'heading' => 'nullable|numeric|between:0,360',
            'accuracy' => 'nullable|numeric|min:0',
            'altitude' => 'nullable|numeric',
            'address' => 'nullable|string|max:255',
            'status' => 'nullable|in:moving,stopped,idle',
        ]);

        $truckId = $validated['truck_id'];

        // Mark all previous locations for this truck as not latest
        GpsLocation::where('truck_id', $truckId)
            ->where('is_latest', true)
            ->update(['is_latest' => false]);

        // Create new GPS location entry
        $gpsLocation = GpsLocation::create([
            'truck_id' => $validated['truck_id'],
            'driver_id' => $validated['driver_id'] ?? null,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'speed' => $validated['speed'] ?? null,
            'heading' => $validated['heading'] ?? null,
            'accuracy' => $validated['accuracy'] ?? null,
            'altitude' => $validated['altitude'] ?? null,
            'address' => $validated['address'] ?? null,
            'status' => $validated['status'] ?? 'moving',
            'is_latest' => true,
            'recorded_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'GPS location updated successfully',
            'data' => $gpsLocation,
        ], 201);
    }

    /**
     * Get latest GPS position of all trucks
     */
    public function latest(Request $request): JsonResponse
    {
        $trucks = Truck::with(['driver', 'company'])
            ->get()
            ->map(function (Truck $truck) {
                $latestLocation = GpsLocation::where('truck_id', $truck->id)
                    ->where('is_latest', true)
                    ->latest('recorded_at')
                    ->first();

                return [
                    'id' => $truck->id,
                    'plate_number' => $truck->plate_number,
                    'brand' => $truck->brand,
                    'model' => $truck->model,
                    'status' => $truck->status,
                    'driver_name' => $truck->driver?->full_name ?? null,
                    'location' => $latestLocation ? [
                        'latitude' => (float) $latestLocation->latitude,
                        'longitude' => (float) $latestLocation->longitude,
                        'speed' => $latestLocation->speed ? (float) $latestLocation->speed : null,
                        'heading' => $latestLocation->heading ? (float) $latestLocation->heading : null,
                        'address' => $latestLocation->address,
                        'status' => $latestLocation->status,
                        'recorded_at' => $latestLocation->recorded_at,
                    ] : null,
                ];
            });

        return response()->json([
            'success' => true,
            'count' => $trucks->count(),
            'trucks' => $trucks,
            'data' => $trucks, // alias for compatibility
        ]);
    }

    /**
     * Get GPS history for a specific truck
     */
    public function history(Request $request, $truckId): JsonResponse
    {
        $validated = $request->validate([
            'hours' => 'nullable|integer|min:1|max:720',
        ]);

        $hours = $validated['hours'] ?? 24;

        // Verify truck exists
        $truck = Truck::findOrFail($truckId);

        $history = GpsLocation::where('truck_id', $truckId)
            ->where('recorded_at', '>=', now()->subHours($hours))
            ->orderBy('recorded_at', 'desc')
            ->limit(100)
            ->get()
            ->map(function (GpsLocation $location) {
                return [
                    'id' => $location->id,
                    'latitude' => (float) $location->latitude,
                    'longitude' => (float) $location->longitude,
                    'speed' => $location->speed ? (float) $location->speed : null,
                    'heading' => $location->heading ? (float) $location->heading : null,
                    'accuracy' => $location->accuracy ? (float) $location->accuracy : null,
                    'altitude' => $location->altitude ? (float) $location->altitude : null,
                    'address' => $location->address,
                    'status' => $location->status,
                    'recorded_at' => $location->recorded_at,
                ];
            });

        return response()->json([
            'success' => true,
            'truck' => [
                'id' => $truck->id,
                'plate_number' => $truck->plate_number,
                'brand' => $truck->brand,
                'model' => $truck->model,
            ],
            'hours' => $hours,
            'count' => $history->count(),
            'data' => $history,
        ]);
    }

    /**
     * Get current position of a specific truck
     */
    public function truckPosition($truckId): JsonResponse
    {
        $truck = Truck::findOrFail($truckId);

        $location = GpsLocation::where('truck_id', $truckId)
            ->where('is_latest', true)
            ->latest('recorded_at')
            ->first();

        if (!$location) {
            return response()->json([
                'success' => false,
                'message' => 'No GPS location found for this truck',
                'truck' => [
                    'id' => $truck->id,
                    'plate_number' => $truck->plate_number,
                    'brand' => $truck->brand,
                    'model' => $truck->model,
                ],
                'location' => null,
            ], 404);
        }

        return response()->json([
            'success' => true,
            'truck' => [
                'id' => $truck->id,
                'plate_number' => $truck->plate_number,
                'brand' => $truck->brand,
                'model' => $truck->model,
                'status' => $truck->status,
                'driver_name' => $truck->driver?->full_name ?? null,
            ],
            'location' => [
                'id' => $location->id,
                'latitude' => (float) $location->latitude,
                'longitude' => (float) $location->longitude,
                'speed' => $location->speed ? (float) $location->speed : null,
                'heading' => $location->heading ? (float) $location->heading : null,
                'accuracy' => $location->accuracy ? (float) $location->accuracy : null,
                'altitude' => $location->altitude ? (float) $location->altitude : null,
                'address' => $location->address,
                'status' => $location->status,
                'recorded_at' => $location->recorded_at,
            ],
        ]);
    }
}
