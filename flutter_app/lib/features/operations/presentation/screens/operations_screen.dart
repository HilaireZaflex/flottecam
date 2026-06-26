import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/operations_provider.dart';
import '../../../auth/data/models/operation_model.dart';
import '../../../trucks/providers/trucks_provider.dart';
import '../../../../core/theme/app_theme.dart';

class OperationsScreen extends ConsumerStatefulWidget {
  const OperationsScreen({super.key});

  @override
  ConsumerState<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends ConsumerState<OperationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int?    _filtreTruckId;
  String  _filtreCategorie = '';
  String  _filtreDateDebut = '';
  String  _filtreDateFin   = '';
  bool    _showFilters     = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasFilter => _filtreTruckId != null || _filtreCategorie.isNotEmpty ||
      _filtreDateDebut.isNotEmpty || _filtreDateFin.isNotEmpty;

  void _resetFilters() => setState(() {
    _filtreTruckId    = null;
    _filtreCategorie  = '';
    _filtreDateDebut  = '';
    _filtreDateFin    = '';
  });

  String get _currentFilter {
    final params = <String>[];
    switch (_tabController.index) {
      case 1: params.add('type_operation=recette'); break;
      case 2: params.add('type_operation=depense'); break;
    }
    if (_filtreTruckId != null)          params.add('truck_id=$_filtreTruckId');
    if (_filtreCategorie.isNotEmpty)     params.add('categorie=$_filtreCategorie');
    if (_filtreDateDebut.isNotEmpty)     params.add('date_debut=$_filtreDateDebut');
    if (_filtreDateFin.isNotEmpty)       params.add('date_fin=$_filtreDateFin');
    return params.join('&');
  }

  @override
  Widget build(BuildContext context) {
    final opsAsync    = ref.watch(operationsProvider(_currentFilter));
    final totauxAsync = ref.watch(operationsTotauxProvider(_currentFilter));
    final trucksAsync = ref.watch(trucksProvider(''));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Opérations', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasFilter)
            IconButton(icon: const Icon(Icons.filter_alt_off_rounded, color: AppTheme.textPrimary), tooltip: 'Effacer filtres', onPressed: _resetFilters),
          IconButton(
            icon: Badge(isLabelVisible: _hasFilter, child: const Icon(Icons.filter_list_rounded, color: AppTheme.textPrimary)),
            tooltip: 'Filtres',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(icon: const Icon(Icons.assessment_rounded, color: AppTheme.textPrimary),       tooltip: 'Rapport Mensuel',       onPressed: () => context.push('/operations/rapport')),
          IconButton(icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.textPrimary),        tooltip: 'Rentabilité par camion', onPressed: () => context.push('/operations/rentabilite')),
          IconButton(icon: const Icon(Icons.upload_file_rounded, color: AppTheme.textPrimary), tooltip: 'Import Excel',       onPressed: () => context.push('/operations/import')),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.textPrimary),
            tooltip: 'Nouvelle opération',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Tout'),
            Tab(text: 'Recettes'),
            Tab(text: 'Dépenses'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Panneau filtres ─────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🔍 Filtres avancés', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                trucksAsync.when(
                  loading: () => const LinearProgressIndicator(color: AppTheme.primary),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (trucks) => DropdownButtonFormField<int?>(
                    value: _filtreTruckId, isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Camion',
                      prefixIcon: const Icon(Icons.local_shipping_rounded, color: AppTheme.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les camions')),
                      ...trucks.map((t) => DropdownMenuItem(value: t.id,
                          child: Text('${t.plateNumber} — ${t.brand}', overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _filtreTruckId = v),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _filtreCategorie.isEmpty ? null : _filtreCategorie, isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: const Icon(Icons.category_rounded, color: AppTheme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes catégories')),
                    ...['carburant','entretien','reparation','pneumatique','peage','salaire','assurance','transport','autre']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase()+c.substring(1)))),
                  ],
                  onChanged: (v) => setState(() => _filtreCategorie = v ?? ''),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: context,
                          initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) setState(() => _filtreDateDebut = d.toIso8601String().substring(0,10));
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date début',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        isDense: true,
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      child: Text(_filtreDateDebut.isEmpty ? 'Choisir...' : _filtreDateDebut,
                          style: TextStyle(fontSize: 13, color: _filtreDateDebut.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: context,
                          initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) setState(() => _filtreDateFin = d.toIso8601String().substring(0,10));
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date fin',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        isDense: true,
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      child: Text(_filtreDateFin.isEmpty ? 'Choisir...' : _filtreDateFin,
                          style: TextStyle(fontSize: 13, color: _filtreDateFin.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)),
                    ),
                  )),
                ]),
              ]),
            ),
          ),
          // Totaux
          totauxAsync.when(
            loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
            data: (totaux) => _TotauxBanner(totaux: totaux),
          ),
          // Liste
          Expanded(
            child: opsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (ops) => ops.isEmpty
                  ? _EmptyState(tabIndex: _tabController.index)
                  : RefreshIndicator(
                      onRefresh: () => ref.read(operationsProvider(_currentFilter).notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: ops.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _OperationCard(
                          op: ops[i],
                          onDelete: () => _confirmDelete(ctx, ops[i]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, OperationModel op) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${op.designation}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(operationsProvider(_currentFilter).notifier).deleteOperation(op.id);
    }
  }

  Future<void> _showCreateDialog(BuildContext ctx) async {
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateOperationSheet(
        onCreated: () => ref.read(operationsProvider(_currentFilter).notifier).refresh(),
      ),
    );
  }
}

// ── Totaux Banner ─────────────────────────────────────────────────────────────

class _TotauxBanner extends StatelessWidget {
  final Map<String, double> totaux;
  const _TotauxBanner({required this.totaux});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        _TotItem('Recettes', totaux['recettes'] ?? 0, AppTheme.successColor, fmt, AppTheme.successGradient),
        const SizedBox(width: 12),
        _TotItem('Dépenses', totaux['depenses'] ?? 0, AppTheme.errorColor, fmt, AppTheme.errorGradient),
        const SizedBox(width: 12),
        _TotItem('Bénéfice', totaux['benefice'] ?? 0,
            (totaux['benefice'] ?? 0) >= 0 ? AppTheme.successColor : AppTheme.errorColor, fmt,
            (totaux['benefice'] ?? 0) >= 0 ? AppTheme.successGradient : AppTheme.errorGradient),
      ]),
    );
  }
}

class _TotItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final NumberFormat fmt;
  final LinearGradient gradient;
  const _TotItem(this.label, this.value, this.color, this.fmt, this.gradient);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('${fmt.format(value)} FCFA',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ── Operation Card ────────────────────────────────────────────────────────────

class _OperationCard extends StatelessWidget {
  final OperationModel op;
  final VoidCallback onDelete;
  const _OperationCard({required this.op, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt  = NumberFormat('#,##0', 'fr_FR');
    final color = op.isRecette ? AppTheme.successColor : AppTheme.errorColor;
    final icon  = op.isRecette ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onDelete,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(op.designation, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(op.categorie, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(op.date.substring(0, 10), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                  if (op.truck != null) ...[
                    const SizedBox(height: 4),
                    Text(op.truckLabel, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ]),
              ),
              const SizedBox(width: 12),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${fmt.format(op.montant)} FCFA',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                const SizedBox(height: 3),
                Text('${fmt.format(op.quantite)} × ${fmt.format(op.prixUnitaire)}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  const _EmptyState({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final labels = ['opération', 'recette', 'dépense'];
    final colors = [AppTheme.primary, AppTheme.successColor, AppTheme.errorColor];
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colors[tabIndex].withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.receipt_long_rounded, size: 40, color: colors[tabIndex]),
      ),
      const SizedBox(height: 20),
      Text('Aucune ${labels[tabIndex]}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Appuyez sur + pour en ajouter une', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
    ]));
  }
}

// ── Create Operation Sheet ────────────────────────────────────────────────────

class _CreateOperationSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateOperationSheet({required this.onCreated});

  @override
  ConsumerState<_CreateOperationSheet> createState() => _CreateOperationSheetState();
}

class _CreateOperationSheetState extends ConsumerState<_CreateOperationSheet> {
  final _formKey        = GlobalKey<FormState>();
  final _designCtrl     = TextEditingController();
  final _qteCtrl        = TextEditingController(text: '1');
  final _prixCtrl       = TextEditingController();
  final _notesCtrl      = TextEditingController();
  String _typeOp        = 'depense';
  String _categorie     = 'carburant';
  String _date          = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int? _truckId;
  bool _isLoading       = false;

  static const List<String> _categoriesDepense = [
    'carburant', 'entretien', 'reparation', 'salaire', 'peage', 'pneumatique', 'assurance', 'autre'
  ];
  static const List<String> _categoriesRecette = [
    'transport', 'client', 'remboursement', 'autre'
  ];

  List<String> get _categories => _typeOp == 'depense' ? _categoriesDepense : _categoriesRecette;

  @override
  void dispose() {
    _designCtrl.dispose(); _qteCtrl.dispose();
    _prixCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(trucksProvider(''));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nouvelle opération', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),

              // Type
              Row(children: [
                Expanded(child: _TypeBtn('Dépense', 'depense', Icons.arrow_upward_rounded, AppTheme.errorColor)),
                const SizedBox(width: 12),
                Expanded(child: _TypeBtn('Recette', 'recette', Icons.arrow_downward_rounded, AppTheme.successColor)),
              ]),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (d != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(d));
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  child: Text(_date, style: const TextStyle(color: AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(height: 14),

              // Désignation
              TextFormField(
                controller: _designCtrl,
                decoration: InputDecoration(
                  labelText: 'Désignation *',
                  prefixIcon: const Icon(Icons.description_rounded, size: 18, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _categories.contains(_categorie) ? _categorie : _categories.first,
                decoration: InputDecoration(
                  labelText: 'Catégorie *',
                  prefixIcon: const Icon(Icons.category_rounded, size: 18, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categorie = v!),
              ),
              const SizedBox(height: 14),

              // Quantité + Prix
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _qteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantité',
                    prefixIcon: const Icon(Icons.format_list_numbered_rounded, size: 18, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalide' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prix unitaire *',
                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Invalide' : null,
                )),
              ]),
              const SizedBox(height: 14),

              // Camion (optionnel)
              trucksAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (trucks) => DropdownButtonFormField<int?>(
                  value: _truckId,
                  decoration: InputDecoration(
                    labelText: 'Camion (optionnel)',
                    prefixIcon: const Icon(Icons.local_shipping_rounded, size: 18, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucun')),
                    ...trucks.map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text('${t.brand} ${t.model} (${t.plateNumber})'),
                    )),
                  ],
                  onChanged: (v) => setState(() => _truckId = v),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note_rounded, size: 18, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Bouton
              Container(
                decoration: BoxDecoration(
                  gradient: _typeOp == 'recette' ? AppTheme.successGradient : AppTheme.errorGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.subtleShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _TypeBtn(String label, String type, IconData icon, Color color) {
    final selected = _typeOp == type;
    return GestureDetector(
      onTap: () => setState(() {
        _typeOp = type;
        _categorie = type == 'depense' ? 'carburant' : 'transport';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: selected ? 2 : 1),
          boxShadow: selected ? AppTheme.subtleShadow : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? color : AppTheme.textSecondary,
            fontSize: 14,
          )),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(operationsProvider('').notifier).createOperation({
        'date':           _date,
        'designation':    _designCtrl.text.trim(),
        'quantite':       double.parse(_qteCtrl.text),
        'prix_unitaire':  double.parse(_prixCtrl.text),
        'type_operation': _typeOp,
        'categorie':      _categorie,
        if (_truckId != null) 'truck_id': _truckId,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Opération enregistrée'),
          backgroundColor: AppTheme.successColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
