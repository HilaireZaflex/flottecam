<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Truck;
use App\Models\Driver;
use App\Models\Transport;
use App\Models\GlobalOperation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * GET /api/dashboard/stats
     * Statistiques globales : camions, chauffeurs, transports, finances
     */
    public function stats(Request $request): JsonResponse
    {
        $companyId = $request->user()->company_id;

        // Trucks
        $trucks = Truck::where('company_id', $companyId);

        // Drivers
        $drivers = Driver::where('company_id', $companyId);

        // Transports
        $transports = Transport::where('company_id', $companyId);

        // Finances (GlobalOperation)
        $ops = GlobalOperation::where('company_id', $companyId);
        $totalRecettes = (clone $ops)->where('type_operation', 'recette')
            ->sum(DB::raw('quantite * prix_unitaire'));
        $totalDepenses = (clone $ops)->where('type_operation', 'depense')
            ->sum(DB::raw('quantite * prix_unitaire'));

        // Montants transports
        $totalTransportMontant = (clone $transports)->whereNotNull('montant_transport')
            ->sum('montant_transport');
        $totalPaye = (clone $transports)->where('statut_paiement', 'paye')
            ->sum('montant_transport');
        $totalNonPaye = (clone $transports)->whereIn('statut_paiement', ['non_paye', 'partiel'])
            ->sum(DB::raw('montant_transport - montant_paye'));

        return response()->json([
            'trucks' => [
                'total'          => (clone $trucks)->count(),
                'available'      => (clone $trucks)->where('status', 'available')->count(),
                'on_mission'     => (clone $trucks)->where('status', 'on_mission')->count(),
                'maintenance'    => (clone $trucks)->where('status', 'maintenance')->count(),
                'out_of_service' => (clone $trucks)->where('status', 'out_of_service')->count(),
            ],
            'drivers' => [
                'total'      => (clone $drivers)->count(),
                'available'  => (clone $drivers)->where('status', 'available')->count(),
                'on_mission' => (clone $drivers)->where('status', 'on_mission')->count(),
                'on_leave'   => (clone $drivers)->where('status', 'on_leave')->count(),
            ],
            'transports' => [
                'total'     => (clone $transports)->count(),
                'pending'   => (clone $transports)->where('status', 'pending')->count(),
                'active'    => (clone $transports)->where('status', 'in_progress')->count(),
                'completed' => (clone $transports)->where('status', 'completed')->count(),
                'cancelled' => (clone $transports)->where('status', 'cancelled')->count(),
                'paye'      => (clone $transports)->where('statut_paiement', 'paye')->count(),
                'non_paye'  => (clone $transports)->where('statut_paiement', 'non_paye')->count(),
            ],
            'financials' => [
                'total_recettes'   => round($totalRecettes, 2),
                'total_depenses'   => round($totalDepenses, 2),
                'benefice'         => round($totalRecettes - $totalDepenses, 2),
                'total_transports' => round($totalTransportMontant, 2),
                'total_paye'       => round($totalPaye, 2),
                'total_non_paye'   => round(max(0, $totalNonPaye), 2),
            ],
        ]);
    }

    /**
     * GET /api/dashboard/map
     */
    public function mapData(Request $request): JsonResponse
    {
        $companyId = $request->user()->company_id;

        $activeTransports = Transport::where('company_id', $companyId)
            ->where('status', 'in_progress')
            ->with(['truck:id,plate_number,brand,model', 'driver:id,first_name,last_name'])
            ->get()
            ->map(fn($t) => [
                'id'          => $t->id,
                'reference'   => $t->reference,
                'truck'       => $t->truck?->plate_number,
                'driver'      => $t->driver?->full_name,
                'origin'      => ['lat' => $t->origin_lat, 'lng' => $t->origin_lng, 'name' => $t->origin],
                'destination' => ['lat' => $t->destination_lat, 'lng' => $t->destination_lng, 'name' => $t->destination],
                'status'      => $t->status,
            ]);

        return response()->json(['transports' => $activeTransports]);
    }

    /**
     * GET /api/dashboard/alerts
     * Alertes intelligentes : assurance, permis, transports retardés, paiements
     */
    public function alerts(Request $request): JsonResponse
    {
        $companyId = $request->user()->company_id;
        $alerts    = [];

        // Camions : assurance expirant dans 30 jours
        Truck::where('company_id', $companyId)
            ->whereNotNull('insurance_expiry')
            ->whereDate('insurance_expiry', '<=', now()->addDays(30))
            ->get()
            ->each(function ($truck) use (&$alerts) {
                $expired = $truck->insurance_expiry->isPast();
                $alerts[] = [
                    'type'    => $expired ? 'error' : 'warning',
                    'icon'    => 'security',
                    'title'   => $expired ? 'Assurance expirée' : 'Assurance bientôt expirée',
                    'message' => "Camion {$truck->plate_number} — expire le {$truck->insurance_expiry->format('d/m/Y')}",
                    'entity'  => 'truck',
                    'id'      => $truck->id,
                ];
            });

        // Camions : visite technique expirant dans 30 jours
        Truck::where('company_id', $companyId)
            ->whereNotNull('technical_control_expiry')
            ->whereDate('technical_control_expiry', '<=', now()->addDays(30))
            ->get()
            ->each(function ($truck) use (&$alerts) {
                $expired = $truck->technical_control_expiry->isPast();
                $alerts[] = [
                    'type'    => $expired ? 'error' : 'warning',
                    'icon'    => 'build',
                    'title'   => $expired ? 'Visite technique expirée' : 'Visite technique bientôt expirée',
                    'message' => "Camion {$truck->plate_number} — expire le {$truck->technical_control_expiry->format('d/m/Y')}",
                    'entity'  => 'truck',
                    'id'      => $truck->id,
                ];
            });

        // Chauffeurs : permis expirant dans 30 jours
        Driver::where('company_id', $companyId)
            ->whereNotNull('license_expiry')
            ->whereDate('license_expiry', '<=', now()->addDays(30))
            ->get()
            ->each(function ($driver) use (&$alerts) {
                $expired = $driver->license_expiry->isPast();
                $alerts[] = [
                    'type'    => $expired ? 'error' : 'warning',
                    'icon'    => 'badge',
                    'title'   => $expired ? 'Permis expiré' : 'Permis bientôt expiré',
                    'message' => "{$driver->full_name} — expire le {$driver->license_expiry->format('d/m/Y')}",
                    'entity'  => 'driver',
                    'id'      => $driver->id,
                ];
            });

        // Transports retardés
        Transport::where('company_id', $companyId)
            ->where('status', 'in_progress')
            ->whereNotNull('scheduled_arrival')
            ->whereDate('scheduled_arrival', '<', now())
            ->get()
            ->each(function ($transport) use (&$alerts) {
                $alerts[] = [
                    'type'    => 'error',
                    'icon'    => 'warning',
                    'title'   => 'Transport en retard',
                    'message' => "Transport {$transport->reference} : {$transport->origin} → {$transport->destination}",
                    'entity'  => 'transport',
                    'id'      => $transport->id,
                ];
            });

        // Transports non payés > 30 jours
        Transport::where('company_id', $companyId)
            ->where('statut_paiement', 'non_paye')
            ->where('status', 'completed')
            ->whereDate('created_at', '<', now()->subDays(30))
            ->whereNotNull('montant_transport')
            ->get()
            ->each(function ($transport) use (&$alerts) {
                $alerts[] = [
                    'type'    => 'warning',
                    'icon'    => 'payments',
                    'title'   => 'Paiement en attente',
                    'message' => "Transport {$transport->reference} — {$transport->montant_transport} non payé (client: {$transport->client_name})",
                    'entity'  => 'transport',
                    'id'      => $transport->id,
                ];
            });

        // ── Alertes intelligentes avancées ───────────────────────────────────────────

        // Alerte : camion non rentable (dépenses > recettes sur 30 derniers jours)
        $trucks = Truck::where('company_id', $companyId)->get();
        foreach ($trucks as $truck) {
            $ops = GlobalOperation::where('company_id', $companyId)
                ->where('truck_id', $truck->id)
                ->where('date', '>=', now()->subDays(30));
            $recettes = (clone $ops)->where('type_operation', 'recette')->sum(DB::raw('quantite * prix_unitaire'));
            $depenses = (clone $ops)->where('type_operation', 'depense')->sum(DB::raw('quantite * prix_unitaire'));
            $montantTransports = Transport::where('company_id', $companyId)
                ->where('truck_id', $truck->id)
                ->where('created_at', '>=', now()->subDays(30))
                ->sum('montant_transport');
            $totalRecettes = $recettes + $montantTransports;
            if ($depenses > 0 && $totalRecettes == 0) {
                $alerts[] = [
                    'type' => 'warning', 'icon' => 'trending_down',
                    'title' => 'Camion non rentable',
                    'message' => "Camion {$truck->plate_number} : aucune recette depuis 30 jours (dépenses: " . number_format($depenses, 0, ',', ' ') . " FCFA)",
                    'entity' => 'truck', 'id' => $truck->id,
                ];
            }
            // Alerte carburant excessif (>60% des dépenses = carburant)
            $carburant = GlobalOperation::where('company_id', $companyId)
                ->where('truck_id', $truck->id)
                ->where('categorie', 'carburant')
                ->where('date', '>=', now()->subDays(30))
                ->sum(DB::raw('quantite * prix_unitaire'));
            if ($depenses > 0 && ($carburant / $depenses) > 0.6) {
                $alerts[] = [
                    'type' => 'warning', 'icon' => 'local_gas_station',
                    'title' => 'Dépenses carburant élevées',
                    'message' => "Camion {$truck->plate_number} : carburant représente " . round($carburant / $depenses * 100) . "% des dépenses du mois",
                    'entity' => 'truck', 'id' => $truck->id,
                ];
            }
        }

        return response()->json(['alerts' => $alerts, 'count' => count($alerts)]);
    }

    /**
     * GET /api/dashboard/chart
     * Données graphique 6 mois (transports + finances)
     */
    public function chartData(Request $request): JsonResponse
    {
        $companyId = $request->user()->company_id;
        $months    = [];

        for ($i = 5; $i >= 0; $i--) {
            $date = now()->subMonths($i);

            $recettes = GlobalOperation::where('company_id', $companyId)
                ->where('type_operation', 'recette')
                ->whereYear('date', $date->year)
                ->whereMonth('date', $date->month)
                ->sum(DB::raw('quantite * prix_unitaire'));

            $depenses = GlobalOperation::where('company_id', $companyId)
                ->where('type_operation', 'depense')
                ->whereYear('date', $date->year)
                ->whereMonth('date', $date->month)
                ->sum(DB::raw('quantite * prix_unitaire'));

            $months[] = [
                'month'      => $date->format('M y'),
                'transports' => Transport::where('company_id', $companyId)
                    ->whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)
                    ->count(),
                'completed'  => Transport::where('company_id', $companyId)
                    ->where('status', 'completed')
                    ->whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)
                    ->count(),
                'recettes'   => round($recettes, 2),
                'depenses'   => round($depenses, 2),
                'benefice'   => round($recettes - $depenses, 2),
            ];
        }

        return response()->json(['chart' => $months]);
    }

    /**
     * GET /api/dashboard/rentabilite
     * Rentabilité par camion
     */
    public function rentabilite(Request $request): JsonResponse
    {
        $companyId = $request->user()->company_id;
        $trucks    = Truck::where('company_id', $companyId)->get();

        $stats = $trucks->map(function ($truck) use ($companyId) {
            $ops      = GlobalOperation::where('company_id', $companyId)->where('truck_id', $truck->id);
            $recettes = (clone $ops)->where('type_operation', 'recette')->sum(DB::raw('quantite * prix_unitaire'));
            $depenses = (clone $ops)->where('type_operation', 'depense')->sum(DB::raw('quantite * prix_unitaire'));
            $montantTransports = Transport::where('company_id', $companyId)
                ->where('truck_id', $truck->id)->sum('montant_transport');
            $nbTransports = Transport::where('company_id', $companyId)
                ->where('truck_id', $truck->id)->count();

            $totalRecettes = $recettes + $montantTransports;

            return [
                'truck'         => $truck->only(['id', 'plate_number', 'brand', 'model', 'status']),
                'recettes'      => round($totalRecettes, 2),
                'depenses'      => round($depenses, 2),
                'benefice'      => round($totalRecettes - $depenses, 2),
                'nb_transports' => $nbTransports,
                'rentable'      => $totalRecettes > $depenses,
            ];
        })->sortByDesc('benefice')->values();

        return response()->json(['rentabilite' => $stats]);
    }

    /**
     * GET /api/dashboard/depenses-categorie
     */
    public function depensesParCategorie(Request $request): JsonResponse
    {
        $companyId  = $request->user()->company_id;
        $categories = GlobalOperation::where('company_id', $companyId)
            ->where('type_operation', 'depense')
            ->selectRaw('categorie, SUM(quantite * prix_unitaire) as total, COUNT(*) as count')
            ->groupBy('categorie')
            ->orderByDesc('total')
            ->get();

        return response()->json(['categories' => $categories]);
    }
}
