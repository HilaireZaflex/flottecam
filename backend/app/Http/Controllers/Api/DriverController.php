<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Truck;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $drivers = Driver::where('company_id', $request->user()->company_id)
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->search, fn($q) => $q->where('first_name', 'like', "%{$request->search}%")
                ->orWhere('last_name', 'like', "%{$request->search}%")
                ->orWhere('phone', 'like', "%{$request->search}%"))
            ->with('truck')
            ->latest()
            ->paginate($request->per_page ?? 20);

        return response()->json($drivers);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'first_name'      => 'required|string|max:100',
            'last_name'       => 'required|string|max:100',
            'email'           => 'nullable|email|unique:drivers',
            'phone'           => 'required|string|max:20',
            'license_number'  => 'required|string|unique:drivers',
            'license_type'    => 'required|string',
            'license_expiry'  => 'required|date',
            'date_of_birth'   => 'nullable|date',
            'address'         => 'nullable|string',
            'city'            => 'nullable|string',
            'country'         => 'nullable|string',
            'current_truck_id'=> 'nullable|integer|exists:trucks,id',
            'notes'           => 'nullable|string',
        ]);

        $driver = Driver::create([
            'company_id' => $request->user()->company_id,
            ...$validated,
            'status' => 'available',
        ]);

        return response()->json([
            'message' => 'Driver created successfully',
            'driver'  => $driver,
        ], 201);
    }

    public function show(Request $request, Driver $driver): JsonResponse
    {
        $this->authorizeCompany($request, $driver->company_id);
        return response()->json(['driver' => $driver->load('truck')]);
    }

    public function update(Request $request, Driver $driver): JsonResponse
    {
        $this->authorizeCompany($request, $driver->company_id);

        $validated = $request->validate([
            'first_name'      => 'sometimes|string',
            'last_name'       => 'sometimes|string',
            'phone'           => 'sometimes|string',
            'license_number'  => 'sometimes|string|unique:drivers,license_number,' . $driver->id,
            'license_type'    => 'sometimes|string',
            'license_expiry'  => 'sometimes|date',
            'status'          => 'sometimes|in:available,on_mission,on_leave,inactive',
            'current_truck_id'=> 'nullable|integer|exists:trucks,id',
            'city'            => 'sometimes|string',
            'country'         => 'sometimes|string',
            'notes'           => 'sometimes|string',
        ]);

        $driver->update($validated);

        return response()->json(['message' => 'Driver updated', 'driver' => $driver->load('truck')]);
    }

    public function destroy(Request $request, Driver $driver): JsonResponse
    {
        $this->authorizeCompany($request, $driver->company_id);
        $driver->delete();
        return response()->json(['message' => 'Driver deleted successfully']);
    }

    public function assignTruck(Request $request, Driver $driver): JsonResponse
    {
        $this->authorizeCompany($request, $driver->company_id);
        $request->validate(['truck_id' => 'nullable|exists:trucks,id']);

        $driver->update(['current_truck_id' => $request->truck_id]);

        if ($request->truck_id) {
            Truck::where('id', $request->truck_id)
                 ->update(['status' => 'available']);
        }

        return response()->json(['message' => 'Truck assigned', 'driver' => $driver->load('truck')]);
    }

    public function transports(Request $request, Driver $driver): JsonResponse
    {
        $this->authorizeCompany($request, $driver->company_id);
        $transports = $driver->transports()->with('truck')->latest()->paginate(15);
        return response()->json($transports);
    }

    private function authorizeCompany(Request $request, int $companyId): void
    {
        if ($request->user()->company_id !== $companyId) {
            abort(403, 'Unauthorized');
        }
    }
}
