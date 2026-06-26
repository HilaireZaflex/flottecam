<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8"/>
<title>Rapport Mensuel — {{ $monthLabel }}</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: DejaVu Sans, Arial, sans-serif; font-size:11px; color:#1a1a2e; }
  .header { background:#1565C0; color:white; padding:20px 28px; margin-bottom:20px; }
  .header h1 { font-size:20px; font-weight:bold; margin-bottom:3px; }
  .header p  { font-size:11px; opacity:0.85; }
  .container { padding:0 28px 28px; }
  h2 { font-size:13px; font-weight:bold; color:#1565C0; border-bottom:2px solid #1565C0; padding-bottom:5px; margin:18px 0 10px; }
  /* Stats row */
  .stats-table { width:100%; border-collapse:separate; border-spacing:8px; margin-bottom:8px; }
  .stat-cell { width:25%; border-radius:6px; padding:10px; text-align:center; border:1px solid #e0e8ff; }
  .stat-green  { background:#f0fff4; border-color:#c6f6d5; }
  .stat-red    { background:#fff5f5; border-color:#fed7d7; }
  .stat-blue   { background:#ebf8ff; border-color:#bee3f8; }
  .stat-orange { background:#fffaf0; border-color:#feebc8; }
  .stat-value  { font-size:13px; font-weight:bold; margin-bottom:3px; }
  .stat-label  { font-size:9px; color:#718096; text-transform:uppercase; }
  .green-text  { color:#276749; }
  .red-text    { color:#c53030; }
  .blue-text   { color:#2b6cb0; }
  /* Tables */
  table.data { width:100%; border-collapse:collapse; margin-bottom:6px; }
  table.data thead th { background:#1565C0; color:white; padding:7px 9px; text-align:left; font-size:10px; }
  table.data tbody tr:nth-child(even) { background:#f7f9ff; }
  table.data tbody td { padding:6px 9px; border-bottom:1px solid #e8edf5; font-size:10px; }
  .badge { display:inline; padding:2px 7px; border-radius:10px; font-size:9px; font-weight:bold; }
  .b-green  { background:#c6f6d5; color:#276749; }
  .b-orange { background:#feebc8; color:#c05621; }
  .b-red    { background:#fed7d7; color:#c53030; }
  .footer { margin-top:28px; padding-top:10px; border-top:1px solid #e2e8f0; font-size:9px; color:#a0aec0; text-align:center; }
  .total-row { font-weight:bold; background:#f0f4ff !important; }
</style>
</head>
<body>

<!-- En-tête -->
<div class="header">
  <h1>Rapport Mensuel — {{ $monthLabel }}</h1>
  <p>{{ $company->name }} &nbsp;|&nbsp; Gestion de flotte de camions &nbsp;|&nbsp; Généré le {{ $generatedAt }}</p>
</div>

<div class="container">

  <!-- Résumé financier -->
  <h2>Résumé Financier</h2>
  <table class="stats-table">
    <tr>
      <td class="stat-cell stat-green">
        <div class="stat-value green-text">{{ number_format($totalRecettes, 0, ',', ' ') }}</div>
        <div class="stat-label">Recettes (FCFA)</div>
      </td>
      <td class="stat-cell stat-red">
        <div class="stat-value red-text">{{ number_format($depenses, 0, ',', ' ') }}</div>
        <div class="stat-label">Dépenses (FCFA)</div>
      </td>
      <td class="stat-cell {{ $benefice >= 0 ? 'stat-blue' : 'stat-red' }}">
        <div class="stat-value {{ $benefice >= 0 ? 'blue-text' : 'red-text' }}">
          {{ number_format($benefice, 0, ',', ' ') }}
        </div>
        <div class="stat-label">Bénéfice (FCFA)</div>
      </td>
      <td class="stat-cell stat-orange">
        <div class="stat-value">{{ $transports->count() }}</div>
        <div class="stat-label">Transports</div>
      </td>
    </tr>
  </table>

  @if($transports->count() > 0)
  <!-- Transports -->
  <h2>Transports du mois</h2>
  <table class="data">
    <thead>
      <tr>
        <th>Camion</th>
        <th>Chauffeur</th>
        <th>Trajet</th>
        <th>Client</th>
        <th>Montant (FCFA)</th>
        <th>Paiement</th>
      </tr>
    </thead>
    <tbody>
      @foreach($transports as $t)
      <tr>
        <td>{{ optional($t->truck)->plate_number ?? '—' }}</td>
        <td>{{ $t->driver ? $t->driver->first_name.' '.$t->driver->last_name : '—' }}</td>
        <td>{{ $t->origin }} → {{ $t->destination }}</td>
        <td>{{ $t->client_name ?? '—' }}</td>
        <td>{{ number_format($t->montant_transport ?? 0, 0, ',', ' ') }}</td>
        <td>
          @if($t->statut_paiement === 'paye')
            <span class="badge b-green">Payé</span>
          @elseif($t->statut_paiement === 'partiel')
            <span class="badge b-orange">Partiel</span>
          @else
            <span class="badge b-red">Non payé</span>
          @endif
        </td>
      </tr>
      @endforeach
    </tbody>
  </table>
  @endif

  @if($categories->count() > 0)
  <!-- Dépenses par catégorie -->
  <h2>Dépenses par Catégorie</h2>
  <table class="data">
    <thead>
      <tr>
        <th>Catégorie</th>
        <th>Montant (FCFA)</th>
        <th>% du total</th>
      </tr>
    </thead>
    <tbody>
      @foreach($categories as $cat)
      <tr>
        <td>{{ ucfirst($cat->categorie) }}</td>
        <td class="red-text">{{ number_format($cat->total, 0, ',', ' ') }}</td>
        <td>{{ $depenses > 0 ? round($cat->total / $depenses * 100) : 0 }}%</td>
      </tr>
      @endforeach
      <tr class="total-row">
        <td>TOTAL DÉPENSES</td>
        <td class="red-text">{{ number_format($depenses, 0, ',', ' ') }}</td>
        <td>100%</td>
      </tr>
    </tbody>
  </table>
  @endif

  @if($operations->count() > 0)
  <!-- Opérations détaillées -->
  <h2>Opérations Détaillées</h2>
  <table class="data">
    <thead>
      <tr>
        <th>Date</th>
        <th>Désignation</th>
        <th>Camion</th>
        <th>Catégorie</th>
        <th>Type</th>
        <th>Montant (FCFA)</th>
      </tr>
    </thead>
    <tbody>
      @foreach($operations->take(30) as $op)
      <tr>
        <td>{{ \Carbon\Carbon::parse($op->date)->format('d/m/Y') }}</td>
        <td>{{ mb_strlen($op->designation) > 35 ? mb_substr($op->designation, 0, 35).'...' : $op->designation }}</td>
        <td>{{ optional($op->truck)->plate_number ?? 'Général' }}</td>
        <td>{{ ucfirst($op->categorie) }}</td>
        <td>
          @if($op->type_operation === 'recette')
            <span class="badge b-green">Recette</span>
          @else
            <span class="badge b-red">Dépense</span>
          @endif
        </td>
        <td class="{{ $op->type_operation === 'recette' ? 'green-text' : 'red-text' }}">
          {{ $op->type_operation === 'recette' ? '+' : '-' }}{{ number_format($op->quantite * $op->prix_unitaire, 0, ',', ' ') }}
        </td>
      </tr>
      @endforeach
    </tbody>
  </table>
  @if($operations->count() > 30)
  <p style="font-size:9px;color:#a0aec0;margin-top:3px;">* Limité aux 30 premières opérations.</p>
  @endif
  @endif

  <div class="footer">
    <strong>Fleet SaaS</strong> — {{ $company->name }} — {{ $company->email ?? '' }} — {{ $company->phone ?? '' }}<br>
    Rapport généré automatiquement le {{ $generatedAt }}
  </div>

</div>
</body>
</html>
