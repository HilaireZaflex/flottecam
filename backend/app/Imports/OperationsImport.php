<?php

namespace App\Imports;

use App\Models\GlobalOperation;
use App\Models\Truck;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\Importable;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;

class OperationsImport implements ToModel, WithHeadingRow, SkipsEmptyRows
{
    use Importable;

    private int $companyId;
    private int $userId;
    private array $errors = [];
    private int $imported = 0;

    public function __construct(int $companyId, int $userId)
    {
        $this->companyId = $companyId;
        $this->userId    = $userId;
    }

    /**
     * Colonnes attendues dans le fichier Excel :
     * date | designation | quantite | prix_unitaire | type_operation | categorie | plaque_camion (opt) | notes (opt)
     */
    public function model(array $row): ?GlobalOperation
    {
        // Validation basique
        if (empty($row['designation']) || empty($row['type_operation'])) {
            return null;
        }

        $typeOp = strtolower(trim($row['type_operation'] ?? ''));
        if (!in_array($typeOp, ['recette', 'depense'])) {
            return null;
        }

        // Chercher le camion par plaque si fourni
        $truckId = null;
        if (!empty($row['plaque_camion'])) {
            $truck = Truck::where('company_id', $this->companyId)
                ->where('plate_number', trim($row['plaque_camion']))
                ->first();
            if ($truck) $truckId = $truck->id;
        }

        // Parser la date
        $date = now()->format('Y-m-d');
        if (!empty($row['date'])) {
            try {
                if (is_numeric($row['date'])) {
                    // Excel date serial number
                    $date = \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($row['date'])->format('Y-m-d');
                } else {
                    $date = \Carbon\Carbon::parse($row['date'])->format('Y-m-d');
                }
            } catch (\Exception $e) {
                $date = now()->format('Y-m-d');
            }
        }

        $this->imported++;

        return new GlobalOperation([
            'company_id'     => $this->companyId,
            'user_id'        => $this->userId,
            'truck_id'       => $truckId,
            'date'           => $date,
            'designation'    => trim($row['designation']),
            'quantite'       => is_numeric($row['quantite'] ?? null) ? (float) $row['quantite'] : 1,
            'prix_unitaire'  => is_numeric($row['prix_unitaire'] ?? null) ? (float) $row['prix_unitaire'] : 0,
            'type_operation' => $typeOp,
            'categorie'      => trim($row['categorie'] ?? 'autre'),
            'notes'          => trim($row['notes'] ?? ''),
        ]);
    }

    public function getImportedCount(): int { return $this->imported; }
    public function getErrors(): array      { return $this->errors; }
}
