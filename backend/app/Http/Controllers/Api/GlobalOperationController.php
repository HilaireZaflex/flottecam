<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GlobalOperation;
use App\Models\Truck;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class GlobalOperationController extends Controller
{
    /**
     * GET /api/operations
     * Liste des opérations (recettes/dépenses) avec filtres
     */
    public function index(Request $request): JsonResponse
    {
        $companyId = Auth::user()->company_id;

        $query = GlobalOperation::with(['truck:id,plate_number,brand,model', 'user:id,name'])
            ->forCompany($companyId)
            ->orderBy('date', 'desc')
            ->orderBy('created_at', 'desc');

        // Filtres
        if ($request->type_operation) {
            $query->where('type_operation', $request->type_operation);
        }
        if ($request->truck_id) {
            $query->where('truck_id', $request->truck_id);
        }
        if ($request->categorie) {
            $query->where('categorie', $request->categorie);
        }
        if ($request->date_debut) {
            $query->whereDate('date', '>=', $request->date_debut);
        }
        if ($request->date_fin) {
            $query->whereDate('date', '<=', $request->date_fin);
        }
        if ($request->search) {
            $search = '%' . $request->search . '%';
            $query->where(function ($q) use ($search) {
                $q->where('designation', 'like', $search)
                  ->orWhere('categorie', 'like', $search);
            });
        }

        $operations = $query->paginate(20);

        // Totaux
        $baseQuery = GlobalOperation::forCompany($companyId);
        if ($request->truck_id) $baseQuery->where('truck_id', $request->truck_id);
        if ($request->date_debut) $baseQuery->whereDate('date', '>=', $request->date_debut);
        if ($request->date_fin) $baseQuery->whereDate('date', '<=', $request->date_fin);

        $totalRecettes = (clone $baseQuery)->recettes()->sum(DB::raw('quantite * prix_unitaire')) + 0.0;
        $totalDepenses = (clone $baseQuery)->depenses()->sum(DB::raw('quantite * prix_unitaire')) + 0.0;

        return response()->json([
            'operations'     => $operations->items(),
            'total'          => $operations->total(),
            'per_page'       => $operations->perPage(),
            'current_page'   => $operations->currentPage(),
            'last_page'      => $operations->lastPage(),
            'totaux' => [
                'recettes' => round($totalRecettes, 2),
                'depenses' => round($totalDepenses, 2),
                'benefice' => round($totalRecettes - $totalDepenses, 2),
            ],
        ]);
    }

    /**
     * POST /api/operations
     * Créer une opération
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'date'          => 'required|date',
            'designation'   => 'required|string|max:255',
            'quantite'      => 'sometimes|numeric|min:0',
            'prix_unitaire' => 'required|numeric|min:0',
            'type_operation'=> 'required|in:recette,depense',
            'categorie'     => 'required|string|max:100',
            'truck_id'      => 'nullable|integer|exists:trucks,id',
            'notes'         => 'nullable|string',
        ]);

        // Vérifier que le camion appartient à la company
        if (!empty($data['truck_id'])) {
            $truck = Truck::where('id', $data['truck_id'])
                          ->where('company_id', Auth::user()->company_id)
                          ->firstOrFail();
        }

        $operation = GlobalOperation::create([
            ...$data,
            'company_id' => Auth::user()->company_id,
            'user_id'    => Auth::id(),
            'quantite'   => $data['quantite'] ?? 1,
        ]);

        // ── Notification intelligente ─────────────────────────────────────────
        $montant  = number_format($operation->quantite * $operation->prix_unitaire, 0, ',', ' ');
        $typeLabel = $operation->type_operation === 'recette' ? '💰 Recette' : '💸 Dépense';
        $users    = \App\Models\User::where('company_id', Auth::user()->company_id)
                      ->whereIn('role', ['admin', 'manager'])->get();
        foreach ($users as $u) {
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id'              => \Illuminate\Support\Str::uuid(),
                'type'            => 'App\Notifications\OperationNotification',
                'notifiable_type' => 'App\Models\User',
                'notifiable_id'   => $u->id,
                'data'            => json_encode([
                    'title'   => "$typeLabel ajoutée",
                    'message' => "{$operation->designation} — {$montant} FCFA",
                    'type'    => $operation->type_operation,
                    'amount'  => $operation->quantite * $operation->prix_unitaire,
                ]),
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
        }

        return response()->json([
            'message'   => 'Opération créée avec succès',
            'operation' => $operation->load(['truck:id,plate_number,brand,model', 'user:id,name']),
        ], 201);
    }

    /**
     * GET /api/operations/{id}
     */
    public function show(int $id): JsonResponse
    {
        $operation = GlobalOperation::with(['truck', 'user'])
            ->where('company_id', Auth::user()->company_id)
            ->findOrFail($id);

        return response()->json(['operation' => $operation]);
    }

    /**
     * PUT /api/operations/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $operation = GlobalOperation::where('company_id', Auth::user()->company_id)->findOrFail($id);

        $data = $request->validate([
            'date'          => 'sometimes|date',
            'designation'   => 'sometimes|string|max:255',
            'quantite'      => 'sometimes|numeric|min:0',
            'prix_unitaire' => 'sometimes|numeric|min:0',
            'type_operation'=> 'sometimes|in:recette,depense',
            'categorie'     => 'sometimes|string|max:100',
            'truck_id'      => 'nullable|integer|exists:trucks,id',
            'notes'         => 'nullable|string',
        ]);

        $operation->update($data);

        return response()->json([
            'message'   => 'Opération mise à jour',
            'operation' => $operation->fresh(['truck:id,plate_number,brand,model', 'user:id,name']),
        ]);
    }

    /**
     * DELETE /api/operations/{id}
     */
    public function destroy(int $id): JsonResponse
    {
        $operation = GlobalOperation::where('company_id', Auth::user()->company_id)->findOrFail($id);
        $operation->delete();

        return response()->json(['message' => 'Opération supprimée']);
    }

    /**
     * GET /api/operations/stats/par-camion
     * Rentabilité par camion
     */
    public function statsByTruck(): JsonResponse
    {
        $companyId = Auth::user()->company_id;

        $trucks = Truck::where('company_id', $companyId)->get();

        $stats = $trucks->map(function ($truck) use ($companyId) {
            $ops    = GlobalOperation::where('company_id', $companyId)->where('truck_id', $truck->id);
            $recettes = (clone $ops)->recettes()->sum(DB::raw('quantite * prix_unitaire')) + 0.0;
            $depenses = (clone $ops)->depenses()->sum(DB::raw('quantite * prix_unitaire')) + 0.0;
            $transports = \App\Models\Transport::where('company_id', $companyId)
                ->where('truck_id', $truck->id)->count();

            return [
                'truck'      => $truck->only(['id', 'plate_number', 'brand', 'model', 'status']),
                'recettes'   => round($recettes, 2),
                'depenses'   => round($depenses, 2),
                'benefice'   => round($recettes - $depenses, 2),
                'transports' => $transports,
                'rentable'   => $recettes > $depenses,
            ];
        })->sortByDesc('benefice')->values();

        return response()->json(['stats' => $stats]);
    }

    /**
     * GET /api/operations/stats/par-categorie
     * Dépenses par catégorie
     */
    public function statsByCategorie(): JsonResponse
    {
        $companyId = Auth::user()->company_id;

        $categories = GlobalOperation::where('company_id', $companyId)
            ->depenses()
            ->selectRaw('categorie, SUM(quantite * prix_unitaire) as total, COUNT(*) as count')
            ->groupBy('categorie')
            ->orderByDesc('total')
            ->get();

        return response()->json(['categories' => $categories]);
    }

    /**
     * GET /api/operations/clients/dettes
     * Clients qui doivent de l'argent (transports non payés)
     */
    public function clientDettes(): JsonResponse
    {
        $companyId = Auth::user()->company_id;

        $dettes = \App\Models\Transport::where('company_id', $companyId)
            ->whereIn('statut_paiement', ['non_paye', 'partiel'])
            ->whereNotNull('client_name')
            ->whereNotNull('montant_transport')
            ->selectRaw("client_name, client_phone, 
                SUM(montant_transport) as total_du,
                SUM(montant_paye) as total_paye,
                SUM(montant_transport - montant_paye) as reste_a_payer,
                COUNT(*) as nb_transports")
            ->groupBy('client_name', 'client_phone')
            ->orderByDesc('reste_a_payer')
            ->get();

        return response()->json(['dettes' => $dettes]);
    }
}
