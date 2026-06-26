<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transport;
use App\Models\GlobalOperation;
use App\Models\Truck;
use App\Models\Driver;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * GET /api/reports/monthly?month=2026-03
     * Rapport mensuel complet
     */
    public function monthlyReport(Request $request): JsonResponse
    {
        $companyId  = $request->user()->company_id;
        $monthParam = $request->query('month', now()->format('Y-m'));

        // Parser le mois — format attendu: YYYY-MM
        [$year, $month] = array_pad(explode('-', $monthParam), 2, null);
        $year  = (int) ($year ?? now()->year);
        $month = (int) ($month ?? now()->month);

        $startOfMonth = \Carbon\Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endOfMonth   = $startOfMonth->copy()->endOfMonth();
        $monthLabel   = $startOfMonth->locale('fr')->isoFormat('MMMM YYYY');

        // ── Transports du mois ────────────────────────────────────────────────────
        $tq = Transport::where('company_id', $companyId)
            ->whereYear('created_at', $year)->whereMonth('created_at', $month);

        $totalTransports   = (clone $tq)->count();
        $transPayes        = (clone $tq)->where('statut_paiement', 'paye')->count();
        $transNonPayes     = (clone $tq)->where('statut_paiement', 'non_paye')->count();
        $montantTransports = (clone $tq)->sum('montant_transport');
        $montantPaye       = (clone $tq)->where('statut_paiement', 'paye')->sum('montant_transport');
        $montantNonPaye    = (clone $tq)->where('statut_paiement', 'non_paye')->sum('montant_transport');

        // ── Opérations du mois ────────────────────────────────────────────────────
        $oq = GlobalOperation::where('company_id', $companyId)
            ->whereYear('date', $year)->whereMonth('date', $month);

        $recettes = (clone $oq)->where('type_operation', 'recette')
            ->sum(DB::raw('quantite * prix_unitaire'));
        $depenses = (clone $oq)->where('type_operation', 'depense')
            ->sum(DB::raw('quantite * prix_unitaire'));

        $totalRecettes = $recettes + $montantTransports;
        $benefice      = $totalRecettes - $depenses;

        // ── Top 3 camions (par nb transports ce mois) ─────────────────────────────
        $topTrucks = Truck::where('trucks.company_id', $companyId)
            ->select(
                'trucks.id', 'trucks.plate_number', 'trucks.brand', 'trucks.model',
                DB::raw('COUNT(t.id) as nb_transports'),
                DB::raw('SUM(t.montant_transport) as montant_total')
            )
            ->leftJoin('transports as t', function ($j) use ($year, $month) {
                $j->on('trucks.id', '=', 't.truck_id')
                  ->whereYear('t.created_at', $year)
                  ->whereMonth('t.created_at', $month);
            })
            ->groupBy('trucks.id', 'trucks.plate_number', 'trucks.brand', 'trucks.model')
            ->orderByDesc('nb_transports')
            ->limit(5)
            ->get()
            ->map(fn ($t) => [
                'id'           => $t->id,
                'plate_number' => $t->plate_number,
                'brand'        => $t->brand,
                'model'        => $t->model,
                'nb_transports'=> (int) $t->nb_transports,
                'montant'      => round((float) ($t->montant_total ?? 0), 2),
            ])->toArray();

        // ── Dépenses par catégorie ────────────────────────────────────────────────
        $categories = GlobalOperation::where('company_id', $companyId)
            ->where('type_operation', 'depense')
            ->whereYear('date', $year)->whereMonth('date', $month)
            ->selectRaw('categorie, SUM(quantite * prix_unitaire) as total, COUNT(*) as count')
            ->groupBy('categorie')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($c) => [
                'categorie'  => $c->categorie,
                'total'      => round((float) $c->total, 2),
                'count'      => (int) $c->count,
                'percentage' => $depenses > 0 ? round($c->total / $depenses * 100) : 0,
            ])->toArray();

        // ── Alertes actives ───────────────────────────────────────────────────────
        $alerts = [];
        $nbExpirations = Truck::where('company_id', $companyId)
            ->where(function ($q) {
                $q->whereDate('insurance_expiry', '<=', now()->addDays(30))
                  ->orWhereDate('technical_control_expiry', '<=', now()->addDays(30));
            })->count();
        if ($nbExpirations > 0) {
            $alerts[] = ['type' => 'error', 'message' => "$nbExpirations document(s) camion expiré(s) ou bientôt"];
        }

        $nbPermisExpires = Driver::where('company_id', $companyId)
            ->whereDate('license_expiry', '<=', now()->addDays(30))->count();
        if ($nbPermisExpires > 0) {
            $alerts[] = ['type' => 'warning', 'message' => "$nbPermisExpires permis expiré(s) ou bientôt"];
        }

        return response()->json([
            'month'        => sprintf('%04d-%02d', $year, $month),
            'month_label'  => $monthLabel,
            'year'         => $year,
            'financials'   => [
                'recettes'          => round($recettes, 2),
                'montant_transports'=> round($montantTransports, 2),
                'total_recettes'    => round($totalRecettes, 2),
                'depenses'          => round($depenses, 2),
                'benefice'          => round($benefice, 2),
            ],
            'transports'   => [
                'total'         => $totalTransports,
                'paye'          => $transPayes,
                'non_paye'      => $transNonPayes,
                'montant_total' => round($montantTransports, 2),
                'montant_paye'  => round($montantPaye, 2),
                'montant_non_paye' => round($montantNonPaye, 2),
            ],
            'top_trucks'   => $topTrucks,
            'categories'   => $categories,
            'alerts'       => $alerts,
            'generated_at' => now()->toIso8601String(),
        ]);
    }

    /**
     * GET /api/reports/monthly/pdf?month=2026-03
     * Télécharger le rapport mensuel en PDF
     */
    public function downloadPdf(Request $request)
    {
        $companyId  = $request->user()->company_id;
        $company    = $request->user()->company;
        $monthParam = $request->query('month', now()->format('Y-m'));

        [$year, $month] = array_pad(explode('-', $monthParam), 2, null);
        $year  = (int) ($year ?? now()->year);
        $month = (int) ($month ?? now()->month);

        $startOfMonth = \Carbon\Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endOfMonth   = $startOfMonth->copy()->endOfMonth();
        $monthLabel   = $startOfMonth->locale('fr')->isoFormat('MMMM YYYY');

        // Données financières
        $tq = Transport::where('company_id', $companyId)
            ->whereYear('created_at', $year)->whereMonth('created_at', $month);
        $oq = GlobalOperation::where('company_id', $companyId)
            ->whereYear('date', $year)->whereMonth('date', $month);

        $transports       = (clone $tq)->with('truck', 'driver')->get();
        $recettes         = (clone $oq)->where('type_operation', 'recette')->sum(DB::raw('quantite * prix_unitaire'));
        $depenses         = (clone $oq)->where('type_operation', 'depense')->sum(DB::raw('quantite * prix_unitaire'));
        $montantTransports= (clone $tq)->sum('montant_transport');
        $totalRecettes    = $recettes + $montantTransports;
        $benefice         = $totalRecettes - $depenses;

        $categories = GlobalOperation::where('company_id', $companyId)
            ->where('type_operation', 'depense')
            ->whereYear('date', $year)->whereMonth('date', $month)
            ->selectRaw('categorie, SUM(quantite * prix_unitaire) as total')
            ->groupBy('categorie')->orderByDesc('total')->get();

        $operationsDetails = (clone $oq)->with('truck')->orderBy('date')->get();

        $data = [
            'company'          => $company,
            'monthLabel'       => $monthLabel,
            'year'             => $year,
            'month'            => $month,
            'recettes'         => $recettes,
            'depenses'         => $depenses,
            'montantTransports'=> $montantTransports,
            'totalRecettes'    => $totalRecettes,
            'benefice'         => $benefice,
            'transports'       => $transports,
            'categories'       => $categories,
            'operations'       => $operationsDetails,
            'generatedAt'      => now()->format('d/m/Y H:i'),
        ];

        $pdf = Pdf::loadView('reports.monthly', $data)
            ->setPaper('a4', 'portrait');

        $filename = "rapport_{$company->name}_{$year}-{$month}.pdf";
        return $pdf->download($filename);
    }
}
