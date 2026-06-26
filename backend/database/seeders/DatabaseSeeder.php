<?php

namespace Database\Seeders;

use App\Models\Company;
use App\Models\User;
use App\Models\Truck;
use App\Models\Driver;
use App\Models\Transport;
use App\Models\GlobalOperation;
use App\Models\Document;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('🌍 Seeding Fleet SaaS — Données Mali/Côte d\'Ivoire...');

        // ── Nettoyer les données existantes ───────────────────────────────────
        \Illuminate\Support\Facades\DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        Document::truncate();
        GlobalOperation::truncate();
        Transport::truncate();
        Driver::truncate();
        Truck::truncate();
        User::where('email', '!=', 'admin@fleet.com')->delete();
        Company::whereIn('name', ['SOTRAMA Bamako', 'Test SaaS'])->delete();
        \Illuminate\Support\Facades\DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        // ── Entreprise : Société de Transport Mali ────────────────────────────
        $company = Company::create([
            'name'                    => 'SOTRAMA Bamako',
            'email'                   => 'contact@sotrama.ml',
            'phone'                   => '+223 20 22 33 44',
            'address'                 => 'Route de Koulikoro, Zone Industrielle',
            'city'                    => 'Bamako',
            'country'                 => 'Mali',
            'is_active'               => true,
            'subscription_plan'       => 'pro',
            'subscription_expires_at' => now()->addYear(),
        ]);

        // ── Utilisateurs ──────────────────────────────────────────────────────
        $admin = User::create([
            'company_id'        => $company->id,
            'name'              => 'Mamadou Konaté',
            'email'             => 'admin@sotrama.ml',
            'password'          => Hash::make('password'),
            'role'              => 'admin',
            'phone'             => '+223 76 11 22 33',
            'email_verified_at' => now(),
        ]);
        User::create([
            'company_id'        => $company->id,
            'name'              => 'Fatoumata Diallo',
            'email'             => 'manager@sotrama.ml',
            'password'          => Hash::make('password'),
            'role'              => 'manager',
            'phone'             => '+223 79 44 55 66',
            'email_verified_at' => now(),
        ]);

        // ── Camions (immatriculations Mali) ───────────────────────────────────
        $trucks = [
            ['plate_number' => 'BKO-1234-A', 'brand' => 'Mercedes', 'model' => 'Actros 2545',  'year' => 2020, 'type' => 'flatbed',   'capacity' => 30.0, 'fuel_type' => 'diesel', 'status' => 'available',      'mileage' => 142000, 'color' => 'Blanc',   'insurance_expiry' => now()->addMonths(8),  'technical_control_expiry' => now()->addMonths(14), 'notes' => 'Camion principal — route Bamako-Abidjan'],
            ['plate_number' => 'BKO-5678-B', 'brand' => 'Volvo',    'model' => 'FH 460',       'year' => 2019, 'type' => 'flatbed',   'capacity' => 28.0, 'fuel_type' => 'diesel', 'status' => 'on_mission',     'mileage' => 198000, 'color' => 'Rouge',   'insurance_expiry' => now()->addMonths(3),  'technical_control_expiry' => now()->addMonths(6),  'notes' => 'En route Bamako→Abidjan'],
            ['plate_number' => 'BKO-9012-C', 'brand' => 'Scania',   'model' => 'R 500',        'year' => 2021, 'type' => 'flatbed',   'capacity' => 32.0, 'fuel_type' => 'diesel', 'status' => 'available',      'mileage' => 87000,  'color' => 'Bleu',    'insurance_expiry' => now()->addMonths(11), 'technical_control_expiry' => now()->addMonths(18), 'notes' => 'Spécialisé marchandises lourdes'],
            ['plate_number' => 'BKO-3456-D', 'brand' => 'MAN',      'model' => 'TGX 26.440',   'year' => 2018, 'type' => 'flatbed',   'capacity' => 25.0, 'fuel_type' => 'diesel', 'status' => 'on_mission',     'mileage' => 265000, 'color' => 'Jaune',   'insurance_expiry' => now()->addMonths(5),  'technical_control_expiry' => now()->addMonths(4),  'notes' => 'En route Abidjan→Bamako'],
            ['plate_number' => 'BKO-7890-E', 'brand' => 'Renault',  'model' => 'T 480',        'year' => 2022, 'type' => 'flatbed',   'capacity' => 27.0, 'fuel_type' => 'diesel', 'status' => 'available',      'mileage' => 54000,  'color' => 'Gris',    'insurance_expiry' => now()->addMonths(12), 'technical_control_expiry' => now()->addMonths(20), 'notes' => 'Camion neuf — faible kilométrage'],
            ['plate_number' => 'BKO-2468-F', 'brand' => 'Mercedes', 'model' => 'Axor 2535',    'year' => 2017, 'type' => 'flatbed',   'capacity' => 22.0, 'fuel_type' => 'diesel', 'status' => 'maintenance',    'mileage' => 380000, 'color' => 'Blanc',   'insurance_expiry' => now()->addMonths(6),  'technical_control_expiry' => now()->subDays(10),   'notes' => 'Révision moteur en cours'],
            ['plate_number' => 'BKO-1357-G', 'brand' => 'DAF',      'model' => 'XF 105',       'year' => 2016, 'type' => 'flatbed',   'capacity' => 20.0, 'fuel_type' => 'diesel', 'status' => 'out_of_service', 'mileage' => 490000, 'color' => 'Vert',    'insurance_expiry' => now()->subMonths(1),  'technical_control_expiry' => now()->subMonths(3),  'notes' => 'Panne moteur — en attente pièces'],
            ['plate_number' => 'BKO-8024-H', 'brand' => 'Iveco',    'model' => 'Trakker 440',  'year' => 2020, 'type' => 'flatbed',   'capacity' => 26.0, 'fuel_type' => 'diesel', 'status' => 'available',      'mileage' => 112000, 'color' => 'Orange',  'insurance_expiry' => now()->addMonths(9),  'technical_control_expiry' => now()->addMonths(15), 'notes' => 'Route secondaire Ségou-Bouaké'],
        ];

        $truckModels = [];
        foreach ($trucks as $data) {
            $truckModels[] = Truck::create([
                'company_id' => $company->id,
                ...$data,
            ]);
        }

        // ── Chauffeurs (noms Mali/Côte d'Ivoire) ─────────────────────────────
        $driversData = [
            ['first_name' => 'Moussa',    'last_name' => 'Coulibaly',  'phone' => '+223 76 11 22 33', 'email' => 'mcoulibaly@sotrama.ml',  'license_number' => 'ML-2019-001', 'license_type' => 'CE', 'status' => 'available',  'city' => 'Bamako',     'country' => 'Mali',          'license_expiry' => now()->addMonths(18)],
            ['first_name' => 'Ibrahim',   'last_name' => 'Traoré',     'phone' => '+223 79 22 33 44', 'email' => 'itraore@sotrama.ml',     'license_number' => 'ML-2018-002', 'license_type' => 'CE', 'status' => 'on_mission', 'city' => 'Ségou',      'country' => 'Mali',          'license_expiry' => now()->addMonths(8)],
            ['first_name' => 'Seydou',    'last_name' => 'Diarra',     'phone' => '+223 65 33 44 55', 'email' => 'sdiarra@sotrama.ml',     'license_number' => 'ML-2020-003', 'license_type' => 'CE', 'status' => 'available',  'city' => 'Bamako',     'country' => 'Mali',          'license_expiry' => now()->addMonths(24)],
            ['first_name' => 'Boubacar',  'last_name' => 'Keïta',      'phone' => '+223 70 44 55 66', 'email' => 'bkeita@sotrama.ml',      'license_number' => 'ML-2017-004', 'license_type' => 'CE', 'status' => 'on_mission', 'city' => 'Koutiala',   'country' => 'Mali',          'license_expiry' => now()->addMonths(5)],
            ['first_name' => 'Adama',     'last_name' => 'Sanogo',     'phone' => '+223 72 55 66 77', 'email' => 'asanogo@sotrama.ml',     'license_number' => 'ML-2021-005', 'license_type' => 'CE', 'status' => 'available',  'city' => 'Bamako',     'country' => 'Mali',          'license_expiry' => now()->addMonths(20)],
            ['first_name' => 'Drissa',    'last_name' => 'Koné',       'phone' => '+223 66 66 77 88', 'email' => 'dkone@sotrama.ml',       'license_number' => 'ML-2016-006', 'license_type' => 'CE', 'status' => 'on_leave',   'city' => 'Sikasso',    'country' => 'Mali',          'license_expiry' => now()->addMonths(3)],
            ['first_name' => 'Mamadou',   'last_name' => 'Bah',        'phone' => '+223 90 77 88 99', 'email' => 'mbah@sotrama.ml',        'license_number' => 'ML-2022-007', 'license_type' => 'CE', 'status' => 'available',  'city' => 'Bamako',     'country' => 'Mali',          'license_expiry' => now()->addMonths(15)],
            ['first_name' => 'Souleymane','last_name' => 'Dembélé',    'phone' => '+223 75 88 99 00', 'email' => 'sdembele@sotrama.ml',    'license_number' => 'ML-2015-008', 'license_type' => 'CE', 'status' => 'inactive',   'city' => 'Mopti',      'country' => 'Mali',          'license_expiry' => now()->subMonths(2)],
        ];

        $driverModels = [];
        foreach ($driversData as $data) {
            $city    = $data['city'];    unset($data['city']);
            $country = $data['country']; unset($data['country']);
            $licenseExpiry = $data['license_expiry']; unset($data['license_expiry']);
            $driverModels[] = Driver::create([
                'company_id'     => $company->id,
                'license_expiry' => $licenseExpiry,
                'date_of_birth'  => now()->subYears(rand(28, 52)),
                'city'           => $city,
                'country'        => $country,
                ...$data,
            ]);
        }

        // ── Transports (routes Mali ↔ Côte d'Ivoire) ─────────────────────────
        // T1 : Bamako → Abidjan (en cours, Volvo BKO-5678-B / Ibrahim Traoré)
        $transport1 = Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[1]->id,
            'driver_id'           => $driverModels[1]->id,
            'origin'              => 'Bamako, Mali',
            'origin_lat'          => 12.6392,
            'origin_lng'          => -8.0029,
            'destination'         => 'Abidjan, Côte d\'Ivoire',
            'destination_lat'     => 5.3600,
            'destination_lng'     => -4.0083,
            'cargo_type'          => 'Produits alimentaires',
            'cargo_weight'        => 25.0,
            'cargo_description'   => 'Riz, mil, farine – CMDT Bamako',
            'status'              => 'in_progress',
            'priority'            => 'high',
            'scheduled_departure' => now()->subHours(8),
            'scheduled_arrival'   => now()->addHours(40),
            'actual_departure'    => now()->subHours(8),
            'client_name'         => 'CMDT Bamako',
            'client_phone'        => '+223 20 22 44 55',
            'client_email'        => 'logistique@cmdt.ml',
            'montant_transport'   => 1800000,
            'statut_paiement'     => 'partiel',
            'montant_paye'        => 900000,
            'distance_km'         => 1228.0,
        ]);

        // T2 : Bamako → Bouaké (en attente, Actros BKO-1234-A / Moussa Coulibaly)
        Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[0]->id,
            'driver_id'           => $driverModels[0]->id,
            'origin'              => 'Bamako, Mali',
            'origin_lat'          => 12.6392,
            'origin_lng'          => -8.0029,
            'destination'         => 'Bouaké, Côte d\'Ivoire',
            'destination_lat'     => 7.6946,
            'destination_lng'     => -5.0340,
            'cargo_type'          => 'Coton brut',
            'cargo_weight'        => 28.0,
            'cargo_description'   => 'Balles de coton CMDT – exportation',
            'status'              => 'pending',
            'priority'            => 'normal',
            'scheduled_departure' => now()->addHours(6),
            'scheduled_arrival'   => now()->addHours(30),
            'client_name'         => 'COIC Bouaké',
            'client_phone'        => '+225 27 31 22 33 44',
            'montant_transport'   => 1500000,
            'statut_paiement'     => 'non_paye',
            'montant_paye'        => 0,
            'distance_km'         => 990.0,
        ]);

        // T3 : Abidjan → Bamako (terminé, Scania BKO-9012-C / Seydou Diarra)
        $transport3 = Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[2]->id,
            'driver_id'           => $driverModels[2]->id,
            'origin'              => 'Abidjan, Côte d\'Ivoire',
            'origin_lat'          => 5.3600,
            'origin_lng'          => -4.0083,
            'destination'         => 'Bamako, Mali',
            'destination_lat'     => 12.6392,
            'destination_lng'     => -8.0029,
            'cargo_type'          => 'Produits manufacturés',
            'cargo_weight'        => 22.0,
            'cargo_description'   => 'Électroménager, textiles – marché de Médine',
            'status'              => 'completed',
            'priority'            => 'normal',
            'scheduled_departure' => now()->subDays(3)->setHour(6),
            'scheduled_arrival'   => now()->subDays(2)->setHour(8),
            'actual_departure'    => now()->subDays(3)->setHour(6)->addMinutes(20),
            'actual_arrival'      => now()->subDays(2)->setHour(7)->addMinutes(45),
            'client_name'         => 'SOCOIM Bamako',
            'client_phone'        => '+223 20 29 11 22',
            'client_email'        => 'import@socoim.ml',
            'montant_transport'   => 2000000,
            'statut_paiement'     => 'paye',
            'montant_paye'        => 2000000,
            'distance_km'         => 1228.0,
            'fuel_consumed'       => 380.0,
        ]);

        // T4 : Bamako → San → Sikasso (en cours, MAN BKO-3456-D / Boubacar Keïta)
        $transport4 = Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[3]->id,
            'driver_id'           => $driverModels[3]->id,
            'origin'              => 'Abidjan, Côte d\'Ivoire',
            'origin_lat'          => 5.3600,
            'origin_lng'          => -4.0083,
            'destination'         => 'Bamako, Mali',
            'destination_lat'     => 12.6392,
            'destination_lng'     => -8.0029,
            'cargo_type'          => 'Carburant',
            'cargo_weight'        => 30.0,
            'cargo_description'   => 'Gasoil en citerne – Total CI',
            'status'              => 'in_progress',
            'priority'            => 'urgent',
            'scheduled_departure' => now()->subHours(12),
            'scheduled_arrival'   => now()->addHours(36),
            'actual_departure'    => now()->subHours(12),
            'client_name'         => 'Total Energies Mali',
            'client_phone'        => '+223 20 23 55 66',
            'montant_transport'   => 2500000,
            'statut_paiement'     => 'non_paye',
            'montant_paye'        => 0,
            'distance_km'         => 1228.0,
        ]);

        // T5 : Sikasso → Abidjan (terminé, payé)
        $transport5 = Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[4]->id,
            'driver_id'           => $driverModels[4]->id,
            'origin'              => 'Sikasso, Mali',
            'origin_lat'          => 11.3170,
            'origin_lng'          => -5.6660,
            'destination'         => 'Abidjan, Côte d\'Ivoire',
            'destination_lat'     => 5.3600,
            'destination_lng'     => -4.0083,
            'cargo_type'          => 'Fruits et légumes',
            'cargo_weight'        => 18.0,
            'cargo_description'   => 'Mangues, oranges – marché Treichville',
            'status'              => 'completed',
            'priority'            => 'high',
            'scheduled_departure' => now()->subDays(5)->setHour(4),
            'scheduled_arrival'   => now()->subDays(4)->setHour(14),
            'actual_departure'    => now()->subDays(5)->setHour(4)->addMinutes(30),
            'actual_arrival'      => now()->subDays(4)->setHour(13)->addMinutes(20),
            'client_name'         => 'Marché Treichville',
            'client_phone'        => '+225 27 21 44 55 66',
            'montant_transport'   => 1200000,
            'statut_paiement'     => 'paye',
            'montant_paye'        => 1200000,
            'distance_km'         => 740.0,
            'fuel_consumed'       => 230.0,
        ]);

        // T6 : Bamako → Ségou (terminé, non payé — dette client)
        $transport6 = Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[7]->id,
            'driver_id'           => $driverModels[6]->id,
            'origin'              => 'Bamako, Mali',
            'origin_lat'          => 12.6392,
            'origin_lng'          => -8.0029,
            'destination'         => 'Ségou, Mali',
            'destination_lat'     => 13.4317,
            'destination_lng'     => -6.2673,
            'cargo_type'          => 'Ciment',
            'cargo_weight'        => 26.0,
            'cargo_description'   => 'Ciment Diamou – chantier BNDA',
            'status'              => 'completed',
            'priority'            => 'normal',
            'scheduled_departure' => now()->subDays(7)->setHour(7),
            'scheduled_arrival'   => now()->subDays(7)->setHour(11),
            'actual_departure'    => now()->subDays(7)->setHour(7),
            'actual_arrival'      => now()->subDays(7)->setHour(11)->addMinutes(20),
            'client_name'         => 'BNDA Ségou',
            'client_phone'        => '+223 20 32 11 22',
            'montant_transport'   => 450000,
            'statut_paiement'     => 'non_paye',
            'montant_paye'        => 0,
            'distance_km'         => 240.0,
            'fuel_consumed'       => 75.0,
        ]);

        // T7 : Koutiala → Abidjan (terminé, payé partiellement)
        $transport7 = Transport::create([
            'company_id'          => $company->id,
            'truck_id'            => $truckModels[2]->id,
            'driver_id'           => $driverModels[2]->id,
            'origin'              => 'Koutiala, Mali',
            'origin_lat'          => 12.3910,
            'origin_lng'          => -5.4660,
            'destination'         => 'Abidjan, Côte d\'Ivoire',
            'destination_lat'     => 5.3600,
            'destination_lng'     => -4.0083,
            'cargo_type'          => 'Coton égrené',
            'cargo_weight'        => 30.0,
            'status'              => 'completed',
            'priority'            => 'normal',
            'scheduled_departure' => now()->subDays(10)->setHour(5),
            'scheduled_arrival'   => now()->subDays(9)->setHour(9),
            'actual_departure'    => now()->subDays(10)->setHour(5),
            'actual_arrival'      => now()->subDays(9)->setHour(8)->addMinutes(40),
            'client_name'         => 'IVOIRE COTON',
            'client_phone'        => '+225 27 30 11 22 33',
            'montant_transport'   => 1700000,
            'statut_paiement'     => 'partiel',
            'montant_paye'        => 850000,
            'distance_km'         => 1100.0,
            'fuel_consumed'       => 340.0,
        ]);

        // ── Opérations globales (recettes + dépenses) — FCFA ─────────────────
        $now = now();
        $ops = [
            // Carburant (prix au litre ~600 FCFA au Mali)
            ['t'=>0,'type'=>'depense','cat'=>'carburant',  'design'=>'Gasoil – Mercedes Actros (Bamako→Abidjan)', 'qte'=>450,'prix'=>600,   'date'=>$now->copy()->subDays(2)],
            ['t'=>1,'type'=>'depense','cat'=>'carburant',  'design'=>'Gasoil – Volvo FH460 (en route Abidjan)',   'qte'=>420,'prix'=>600,   'date'=>$now->copy()->subDays(1)],
            ['t'=>2,'type'=>'depense','cat'=>'carburant',  'design'=>'Gasoil – Scania R500 (retour Bamako)',      'qte'=>400,'prix'=>600,   'date'=>$now->copy()->subDays(4)],
            ['t'=>3,'type'=>'depense','cat'=>'carburant',  'design'=>'Gasoil – MAN TGX (Abidjan→Bamako)',         'qte'=>460,'prix'=>600,   'date'=>$now->copy()->subDays(2)],
            ['t'=>4,'type'=>'depense','cat'=>'carburant',  'design'=>'Gasoil – Renault T480 (Sikasso→Abidjan)',   'qte'=>350,'prix'=>600,   'date'=>$now->copy()->subDays(6)],
            ['t'=>7,'type'=>'depense','cat'=>'carburant',  'design'=>'Gasoil – Iveco Trakker (Bamako→Ségou)',     'qte'=>180,'prix'=>600,   'date'=>$now->copy()->subDays(8)],
            // Entretien
            ['t'=>0,'type'=>'depense','cat'=>'entretien',  'design'=>'Vidange + filtres – Mercedes Actros',       'qte'=>1,  'prix'=>75000, 'date'=>$now->copy()->subDays(15)],
            ['t'=>2,'type'=>'depense','cat'=>'entretien',  'design'=>'Vidange + courroie – Scania R500',           'qte'=>1,  'prix'=>65000, 'date'=>$now->copy()->subDays(20)],
            ['t'=>4,'type'=>'depense','cat'=>'entretien',  'design'=>'Vidange + filtre air – Renault T480',        'qte'=>1,  'prix'=>55000, 'date'=>$now->copy()->subDays(12)],
            // Réparation (camion en maintenance)
            ['t'=>5,'type'=>'depense','cat'=>'reparation', 'design'=>'Révision moteur – Mercedes Axor (panne)',    'qte'=>1,  'prix'=>850000,'date'=>$now->copy()->subDays(5)],
            ['t'=>6,'type'=>'depense','cat'=>'reparation', 'design'=>'Boîte de vitesse – DAF XF (HS)',             'qte'=>1,  'prix'=>1200000,'date'=>$now->copy()->subDays(10)],
            // Pneumatiques
            ['t'=>0,'type'=>'depense','cat'=>'pneumatique','design'=>'Pneus x6 – Mercedes Actros',                'qte'=>6,  'prix'=>85000, 'date'=>$now->copy()->subDays(30)],
            ['t'=>3,'type'=>'depense','cat'=>'pneumatique','design'=>'Pneus x4 – MAN TGX',                        'qte'=>4,  'prix'=>85000, 'date'=>$now->copy()->subDays(18)],
            // Péages (douane Mali-CI, routes)
            ['t'=>1,'type'=>'depense','cat'=>'peage',      'design'=>'Péage + douane Bamako–Abidjan',              'qte'=>1,  'prix'=>45000, 'date'=>$now->copy()->subDays(1)],
            ['t'=>3,'type'=>'depense','cat'=>'peage',      'design'=>'Péage + douane Abidjan–Bamako',              'qte'=>1,  'prix'=>42000, 'date'=>$now->copy()->subDays(2)],
            ['t'=>2,'type'=>'depense','cat'=>'peage',      'design'=>'Péage Abidjan–Bamako – retour',              'qte'=>1,  'prix'=>44000, 'date'=>$now->copy()->subDays(4)],
            // Salaires chauffeurs
            [null, 'type'=>'depense','cat'=>'salaire',     'design'=>'Salaires chauffeurs – Mars 2026',            'qte'=>8,  'prix'=>150000,'date'=>$now->copy()->startOfMonth()],
            [null, 'type'=>'depense','cat'=>'salaire',     'design'=>'Salaires chauffeurs – Février 2026',         'qte'=>8,  'prix'=>150000,'date'=>$now->copy()->subMonths(1)->startOfMonth()],
            // Assurance
            [null, 'type'=>'depense','cat'=>'assurance',   'design'=>'Assurance flotte 8 camions – 2026',          'qte'=>1,  'prix'=>2400000,'date'=>$now->copy()->subMonths(2)],
            // Recettes transports ce mois
            ['t'=>2,'type'=>'recette','cat'=>'transport',  'design'=>'Abidjan→Bamako – SOCOIM (électroménager)',   'qte'=>1,  'prix'=>2000000,'date'=>$now->copy()->subDays(3)],
            ['t'=>4,'type'=>'recette','cat'=>'transport',  'design'=>'Sikasso→Abidjan – Marché Treichville',       'qte'=>1,  'prix'=>1200000,'date'=>$now->copy()->subDays(6)],
            ['t'=>7,'type'=>'recette','cat'=>'transport',  'design'=>'Bamako→Ségou – BNDA (ciment)',               'qte'=>1,  'prix'=>450000, 'date'=>$now->copy()->subDays(8)],
            // Recettes mois précédent
            ['t'=>0,'type'=>'recette','cat'=>'transport',  'design'=>'Bamako→Abidjan – CMDT (coton)',               'qte'=>1,  'prix'=>1900000,'date'=>$now->copy()->subMonths(1)->subDays(5)],
            ['t'=>2,'type'=>'recette','cat'=>'transport',  'design'=>'Koutiala→Abidjan – IVOIRE COTON',             'qte'=>1,  'prix'=>1700000,'date'=>$now->copy()->subMonths(1)->subDays(10)],
            ['t'=>1,'type'=>'recette','cat'=>'transport',  'design'=>'Bamako→Bouaké – marchandises diverses',       'qte'=>1,  'prix'=>1400000,'date'=>$now->copy()->subMonths(1)->subDays(15)],
            ['t'=>3,'type'=>'recette','cat'=>'transport',  'design'=>'Abidjan→Bamako – Total Energies Mali',        'qte'=>1,  'prix'=>2200000,'date'=>$now->copy()->subMonths(1)->subDays(8)],
            // Recettes mois -2
            ['t'=>0,'type'=>'recette','cat'=>'transport',  'design'=>'Bamako→Abidjan – SOTELMA (équipements)',      'qte'=>1,  'prix'=>1600000,'date'=>$now->copy()->subMonths(2)->subDays(3)],
            ['t'=>2,'type'=>'recette','cat'=>'transport',  'design'=>'Abidjan→Bamako – importation générale',       'qte'=>1,  'prix'=>1800000,'date'=>$now->copy()->subMonths(2)->subDays(12)],
        ];

        foreach ($ops as $op) {
            $truckIdx = $op['t'] ?? null;
            GlobalOperation::create([
                'company_id'     => $company->id,
                'truck_id'       => $truckIdx !== null ? $truckModels[$truckIdx]->id : null,
                'user_id'        => $admin->id,
                'date'           => $op['date'],
                'designation'    => $op['design'],
                'quantite'       => $op['qte'],
                'prix_unitaire'  => $op['prix'],
                'type_operation' => $op['type'],
                'categorie'      => $op['cat'],
            ]);
        }

        // ── Documents ─────────────────────────────────────────────────────────
        $docs = [
            ['t'=>0,'type'=>'assurance',       'name'=>'Assurance Mercedes Actros BKO-1234-A',  'expiry'=>now()->addMonths(8)],
            ['t'=>0,'type'=>'carte_grise',     'name'=>'Carte grise BKO-1234-A',                'expiry'=>null],
            ['t'=>0,'type'=>'visite_technique','name'=>'Visite technique BKO-1234-A',            'expiry'=>now()->addMonths(14)],
            ['t'=>0,'type'=>'vignette',        'name'=>'Vignette Mali 2026 – BKO-1234-A',        'expiry'=>now()->addMonths(9)],
            ['t'=>1,'type'=>'assurance',       'name'=>'Assurance Volvo FH460 BKO-5678-B',       'expiry'=>now()->addMonths(3)],
            ['t'=>1,'type'=>'carte_grise',     'name'=>'Carte grise BKO-5678-B',                 'expiry'=>null],
            ['t'=>1,'type'=>'visite_technique','name'=>'Visite technique BKO-5678-B',             'expiry'=>now()->addDays(25)],
            ['t'=>2,'type'=>'assurance',       'name'=>'Assurance Scania R500 BKO-9012-C',       'expiry'=>now()->addMonths(11)],
            ['t'=>2,'type'=>'carte_grise',     'name'=>'Carte grise BKO-9012-C',                 'expiry'=>null],
            ['t'=>3,'type'=>'assurance',       'name'=>'Assurance MAN TGX BKO-3456-D',           'expiry'=>now()->addMonths(5)],
            ['t'=>3,'type'=>'visite_technique','name'=>'Visite technique BKO-3456-D',             'expiry'=>now()->addMonths(4)],
            ['t'=>4,'type'=>'assurance',       'name'=>'Assurance Renault T480 BKO-7890-E',      'expiry'=>now()->addMonths(12)],
            ['t'=>4,'type'=>'visite_technique','name'=>'Visite technique BKO-7890-E',             'expiry'=>now()->addMonths(20)],
            ['t'=>5,'type'=>'assurance',       'name'=>'Assurance Mercedes Axor BKO-2468-F',     'expiry'=>now()->addMonths(6)],
            ['t'=>5,'type'=>'visite_technique','name'=>'Visite technique BKO-2468-F (expirée)',   'expiry'=>now()->subDays(10)],
            ['t'=>6,'type'=>'assurance',       'name'=>'Assurance DAF XF BKO-1357-G (expirée)',  'expiry'=>now()->subMonths(1)],
            ['t'=>6,'type'=>'visite_technique','name'=>'Visite technique BKO-1357-G (expirée)',   'expiry'=>now()->subMonths(3)],
            ['t'=>7,'type'=>'assurance',       'name'=>'Assurance Iveco Trakker BKO-8024-H',     'expiry'=>now()->addMonths(9)],
            ['t'=>7,'type'=>'carte_grise',     'name'=>'Carte grise BKO-8024-H',                 'expiry'=>null],
        ];

        foreach ($docs as $doc) {
            Document::create([
                'company_id'        => $company->id,
                'documentable_type' => 'App\\Models\\Truck',
                'documentable_id'   => $truckModels[$doc['t']]->id,
                'type'              => $doc['type'],
                'name'              => $doc['name'],
                'file_path'         => 'documents/placeholder.pdf',
                'expiry_date'       => $doc['expiry'],
            ]);
        }

        $this->command->info('✅ Seeder terminé !');
        $this->command->info('   Société  : SOTRAMA Bamako');
        $this->command->info('   Login    : admin@sotrama.ml / password');
        $this->command->info('   Camions  : 8 | Chauffeurs : 8 | Transports : 7');
    }
}
