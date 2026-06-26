<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Truck;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TruckController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $trucks = Truck::where('company_id', $request->user()->company_id)
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->search, fn($q) => $q->where(function($sub) use ($request) {
                $s = "%{$request->search}%";
                $sub->where('plate_number',   'like', $s)
                    ->orWhere('brand',         'like', $s)
                    ->orWhere('model',         'like', $s)
                    ->orWhere('proprietaire',  'like', $s)
                    ->orWhere('ville_actuelle','like', $s);
            }))
            ->with(['driver', 'activeTransport'])
            ->latest()
            ->paginate($request->per_page ?? 20);

        return response()->json($trucks);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'plate_number'             => 'required|string|unique:trucks',
            'brand'                    => 'required|string',
            'model'                    => 'required|string',
            'year'                     => 'required|integer|min:1990',
            'type'                     => 'required|string',
            'capacity'                 => 'required|numeric|min:0',
            'fuel_type'                => 'required|string',
            'mileage'                  => 'nullable|integer',
            'color'                    => 'nullable|string',
            'vin'                      => 'nullable|string',
            'insurance_expiry'         => 'nullable|date',
            'technical_control_expiry' => 'nullable|date',
            'notes'                    => 'nullable|string',
        ]);

        $truck = Truck::create([
            'company_id' => $request->user()->company_id,
            ...$validated,
        ]);

        return response()->json([
            'message' => 'Truck created successfully',
            'truck'   => $truck,
        ], 201);
    }

    public function show(Request $request, Truck $truck): JsonResponse
    {
        $this->authorizeCompany($request, $truck->company_id);
        return response()->json(['truck' => $truck->load('driver', 'documents', 'activeTransport')]);
    }

    public function update(Request $request, Truck $truck): JsonResponse
    {
        $this->authorizeCompany($request, $truck->company_id);

        $validated = $request->validate([
            'plate_number'             => 'sometimes|string|unique:trucks,plate_number,' . $truck->id,
            'brand'                    => 'sometimes|string',
            'model'                    => 'sometimes|string',
            'year'                     => 'sometimes|integer',
            'capacity'                 => 'sometimes|numeric',
            'mileage'                  => 'sometimes|integer',
            'fuel_type'                => 'sometimes|string',
            'insurance_expiry'         => 'sometimes|date',
            'technical_control_expiry' => 'sometimes|date',
            'notes'                    => 'sometimes|string',
        ]);

        $truck->update($validated);

        return response()->json(['message' => 'Truck updated', 'truck' => $truck]);
    }

    public function destroy(Request $request, Truck $truck): JsonResponse
    {
        $this->authorizeCompany($request, $truck->company_id);
        $truck->delete();
        return response()->json(['message' => 'Truck deleted successfully']);
    }

    public function updateStatus(Request $request, Truck $truck): JsonResponse
    {
        $this->authorizeCompany($request, $truck->company_id);
        $request->validate(['status' => 'required|in:available,on_mission,maintenance,out_of_service']);
        $truck->update(['status' => $request->status]);
        return response()->json(['message' => 'Status updated', 'truck' => $truck]);
    }

    public function transports(Request $request, Truck $truck): JsonResponse
    {
        $this->authorizeCompany($request, $truck->company_id);
        $transports = $truck->transports()->with('driver')->latest()->paginate(15);
        return response()->json($transports);
    }

    private function authorizeCompany(Request $request, int $companyId): void
    {
        if ($request->user()->company_id !== $companyId) {
            abort(403, 'Unauthorized');
        }
    }
}
