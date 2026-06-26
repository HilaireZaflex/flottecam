<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Imports\OperationsImport;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Maatwebsite\Excel\Facades\Excel;

class ImportController extends Controller
{
    /**
     * POST /api/import/operations
     * Importer des opérations depuis un fichier Excel/CSV
     *
     * Format attendu (ligne d'en-tête obligatoire) :
     * date | designation | quantite | prix_unitaire | type_operation | categorie | plaque_camion | notes
     */
    public function importOperations(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv|max:5120', // 5MB max
        ]);

        try {
            $import = new OperationsImport(
                $request->user()->company_id,
                $request->user()->id
            );

            Excel::import($import, $request->file('file'));

            return response()->json([
                'success'  => true,
                'message'  => "{$import->getImportedCount()} opération(s) importée(s) avec succès",
                'imported' => $import->getImportedCount(),
                'errors'   => $import->getErrors(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'import : ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * GET /api/import/template
     * Retourner un exemple CSV téléchargeable
     */
    public function downloadTemplate(): \Symfony\Component\HttpFoundation\Response
    {
        $csv = "date,designation,quantite,prix_unitaire,type_operation,categorie,plaque_camion,notes\n";
        $csv .= date('Y-m-d') . ",Gasoil plein,300,650,depense,carburant,AB-123-CD,Trajet Paris-Lyon\n";
        $csv .= date('Y-m-d') . ",Transport client Carrefour,1,500000,recette,transport,EF-456-GH,Payé à la livraison\n";
        $csv .= date('Y-m-d') . ",Vidange moteur,1,45000,depense,entretien,AB-123-CD,Garage Central\n";
        $csv .= date('Y-m-d') . ",Salaire chauffeur Mohamed,1,85000,depense,salaire,,Mars 2026\n";

        return response($csv, 200, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => 'attachment; filename="template_import_operations.csv"',
        ]);
    }
}
