<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transport;
use App\Models\Truck;
use App\Models\Driver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transports = Transport::where('company_id', $request->user()->company_id)
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->driver_id, fn($q) => $q->where('driver_id', $request->driver_id))
            ->when($request->truck_id, fn($q) => $q->where('truck_id', $request->truck_id))
            ->when($request->search, fn($q) => $q->where('reference', 'like', "%{$request->search}%")
                ->orWhere('origin', 'like', "%{$request->search}%")
                ->orWhere('destination', 'like', "%{$request->search}%"))
            ->with(['truck', 'driver'])
            ->latest()
            ->paginate($request->per_page ?? 20);

        return response()->json($transports);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'truck_id'            => 'required|exists:trucks,id',
            'driver_id'           => 'required|exists:drivers,id',
            'origin'              => 'required|string',
            'origin_lat'          => 'nullable|numeric',
            'origin_lng'          => 'nullable|numeric',
            'destination'         => 'required|string',
            'destination_lat'     => 'nullable|numeric',
            'destination_lng'     => 'nullable|numeric',
            'cargo_type'          => 'required|string',
            'cargo_weight'        => 'nullable|numeric',
            'cargo_description'   => 'nullable|string',
            'priority'            => 'nullable|in:low,normal,high,urgent',
            'scheduled_departure' => 'required|date',
            'scheduled_arrival'   => 'required|date|after:scheduled_departure',
            'client_name'         => 'nullable|string',
            'client_phone'        => 'nullable|string',
            'client_email'        => 'nullable|email',
            'notes'               => 'nullable|string',
        ]);

        $transport = Transport::create([
            'company_id' => $request->user()->company_id,
            'status'     => 'pending',
            ...$validated,
        ]);

        // Update truck & driver status
        Truck::where('id', $validated['truck_id'])->update(['status' => 'on_mission']);
        Driver::where('id', $validated['driver_id'])->update(['status' => 'on_mission']);

        // ── Notification nouveau transport ────────────────────────────────────
        $users = \App\Models\User::where('company_id', $request->user()->company_id)
                   ->whereIn('role', ['admin', 'manager'])->get();
        foreach ($users as $u) {
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id'              => \Illuminate\Support\Str::uuid(),
                'type'            => 'App\Notifications\TransportNotification',
                'notifiable_type' => 'App\Models\User',
                'notifiable_id'   => $u->id,
                'data'            => json_encode([
                    'title'        => '🚛 Nouveau transport créé',
                    'message'      => "{$transport->origin} → {$transport->destination} — {$transport->client_name}",
                    'transport_id' => $transport->id,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json([
            'message'   => 'Transport created successfully',
            'transport' => $transport->load('truck', 'driver'),
        ], 201);
    }

    public function show(Request $request, Transport $transport): JsonResponse
    {
        $this->authorizeCompany($request, $transport->company_id);
        return response()->json([
            'transport' => $transport->load('truck', 'driver', 'operations.user'),
        ]);
    }

    public function update(Request $request, Transport $transport): JsonResponse
    {
        $this->authorizeCompany($request, $transport->company_id);

        $validated = $request->validate([
            'origin'              => 'sometimes|string',
            'destination'         => 'sometimes|string',
            'cargo_type'          => 'sometimes|string',
            'cargo_weight'        => 'sometimes|numeric',
            'priority'            => 'sometimes|in:low,normal,high,urgent',
            'scheduled_departure' => 'sometimes|date',
            'scheduled_arrival'   => 'sometimes|date',
            'notes'               => 'sometimes|string',
        ]);

        $transport->update($validated);

        return response()->json(['message' => 'Transport updated', 'transport' => $transport]);
    }

    public function destroy(Request $request, Transport $transport): JsonResponse
    {
        $this->authorizeCompany($request, $transport->company_id);

        if ($transport->status === 'in_progress') {
            return response()->json(['message' => 'Cannot delete an in-progress transport'], 422);
        }

        // Free up truck and driver
        if ($transport->truck_id) {
            Truck::where('id', $transport->truck_id)->update(['status' => 'available']);
        }
        if ($transport->driver_id) {
            Driver::where('id', $transport->driver_id)->update(['status' => 'available']);
        }

        $transport->delete();
        return response()->json(['message' => 'Transport deleted successfully']);
    }

    public function updateStatus(Request $request, Transport $transport): JsonResponse
    {
        $this->authorizeCompany($request, $transport->company_id);

        $request->validate([
            'status'          => 'required|in:pending,in_progress,completed,cancelled,delayed',
            'actual_departure'=> 'sometimes|date',
            'actual_arrival'  => 'sometimes|date',
        ]);

        $data = ['status' => $request->status];

        if ($request->status === 'in_progress') {
            $data['actual_departure'] = $request->actual_departure ?? now();
            Truck::where('id', $transport->truck_id)->update(['status' => 'on_mission']);
            Driver::where('id', $transport->driver_id)->update(['status' => 'on_mission']);
        }

        if (in_array($request->status, ['completed', 'cancelled'])) {
            $data['actual_arrival'] = $request->actual_arrival ?? now();
            Truck::where('id', $transport->truck_id)->update(['status' => 'available']);
            Driver::where('id', $transport->driver_id)->update(['status' => 'available']);
        }

        $transport->update($data);

        return response()->json(['message' => 'Status updated', 'transport' => $transport]);
    }

    public function confirmRetour(Request $request, Transport $transport): JsonResponse
    {
        $this->authorizeCompany($request, $transport->company_id);

        // Marquer le transport comme terminé avec l'heure de retour
        $transport->update([
            'status'        => 'completed',
            'actual_arrival'=> now(),
        ]);

        // Libérer le camion et le chauffeur
        Truck::where('id', $transport->truck_id)->update(['status' => 'available']);
        Driver::where('id', $transport->driver_id)->update(['status' => 'available']);

        // Notification de retour
        $notifUsers = \App\Models\User::where('company_id', $request->user()->company_id)
                        ->whereIn('role', ['admin', 'manager'])->get();
        foreach ($notifUsers as $u) {
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id'              => \Illuminate\Support\Str::uuid(),
                'type'            => 'App\Notifications\RetourNotification',
                'notifiable_type' => 'App\Models\User',
                'notifiable_id'   => $u->id,
                'data'            => json_encode([
                    'title'        => '🏁 Retour confirmé',
                    'message'      => "{$transport->origin} → {$transport->destination} — Camion de retour",
                    'transport_id' => $transport->id,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json([
            'message'   => 'Retour confirmé avec succès',
            'transport' => $transport->fresh(),
        ]);
    }

    private function authorizeCompany(Request $request, int $companyId): void
    {
        if ($request->user()->company_id !== $companyId) {
            abort(403, 'Unauthorized');
        }
    }

    /**
     * PATCH /api/transports/{transport}/paiement
     * Mettre à jour le statut de paiement
     */
    public function updatePaiement(Request $request, Transport $transport): \Illuminate\Http\JsonResponse
    {
        if ($request->user()->company_id !== $transport->company_id) {
            abort(403, 'Unauthorized');
        }

        $data = $request->validate([
            'statut_paiement'   => 'required|in:non_paye,paye,partiel',
            'montant_paye'      => 'sometimes|numeric|min:0',
            'montant_transport' => 'sometimes|numeric|min:0',
        ]);

        if (isset($data['montant_transport'])) {
            $transport->montant_transport = $data['montant_transport'];
        }

        $oldStatut = $transport->statut_paiement;
        $transport->statut_paiement = $data['statut_paiement'];
        if ($data['statut_paiement'] === 'paye') {
            $transport->montant_paye = $transport->montant_transport ?? 0;
        } elseif (isset($data['montant_paye'])) {
            $transport->montant_paye = $data['montant_paye'];
        }
        $transport->save();

        // ── Notification paiement ─────────────────────────────────────────────
        if ($oldStatut !== $data['statut_paiement']) {
            $montant = number_format($transport->montant_paye ?? 0, 0, ',', ' ');
            $label   = $data['statut_paiement'] === 'paye' ? '✅ Transport payé' : '⚡ Paiement partiel';
            $notifUsers = \App\Models\User::where('company_id', $request->user()->company_id)
                            ->whereIn('role', ['admin', 'manager'])->get();
            foreach ($notifUsers as $u) {
                \Illuminate\Support\Facades\DB::table('notifications')->insert([
                    'id'              => \Illuminate\Support\Str::uuid(),
                    'type'            => 'App\Notifications\PaiementNotification',
                    'notifiable_type' => 'App\Models\User',
                    'notifiable_id'   => $u->id,
                    'data'            => json_encode([
                        'title'        => $label,
                        'message'      => "{$transport->origin} → {$transport->destination} — {$montant} FCFA",
                        'transport_id' => $transport->id,
                    ]),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }

        return response()->json([
            'message'   => 'Paiement mis à jour',
            'transport' => $transport->fresh(['truck', 'driver']),
        ]);
    }
}
