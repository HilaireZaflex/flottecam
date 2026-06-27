import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/transports_provider.dart';
import '../../../auth/data/models/transport_model.dart';
import '../../../trucks/providers/trucks_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class TransportsScreen extends ConsumerStatefulWidget {
  const TransportsScreen({super.key});
  @override
  ConsumerState<TransportsScreen> createState() => _TransportsScreenState();
}

class _TransportsScreenState extends ConsumerState<TransportsScreen> {
  String _filtreStatutPaiement = '';  // '', 'paye', 'non_paye', 'partiel'
  String _filtreStatut         = '';  // '', 'pending', 'in_progress', 'completed'
  int?   _filtreTruckId;
  String _filtreTruckLabel     = 'Tous les camions';
  bool   _showFilters          = false;

  String get _queryString {
    final params = <String>[];
    if (_filtreStatutPaiement.isNotEmpty) params.add('statut_paiement=$_filtreStatutPaiement');
    if (_filtreStatut.isNotEmpty)         params.add('status=$_filtreStatut');
    if (_filtreTruckId != null)           params.add('truck_id=$_filtreTruckId');
    return params.join('&');
  }

  bool get _hasFilter => _filtreStatutPaiement.isNotEmpty || _filtreStatut.isNotEmpty || _filtreTruckId != null;

  void _resetFilters() => setState(() {
    _filtreStatutPaiement = '';
    _filtreStatut         = '';
    _filtreTruckId        = null;
    _filtreTruckLabel     = 'Tous les camions';
  });

  @override
  Widget build(BuildContext context) {
    final transportsAsync = ref.watch(transportsProvider(_queryString));
    final trucksAsync     = ref.watch(trucksProvider(''));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Transports',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textPrimary)),
        actions: [
          if (_hasFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, color: AppTheme.errorColor),
              tooltip: 'Effacer les filtres',
              onPressed: _resetFilters,
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasFilter,
              backgroundColor: AppTheme.errorColor,
              child: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryColor),
            ),
            tooltip: 'Filtres',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          // ── Bouton Nouveau Voyage ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/transports/new'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Nouveau',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Panneau filtres ─────────────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Filtres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),

              // Filtre statut paiement
              const Text('Paiement', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _FilterChip(label: 'Tous',     value: '',          selected: _filtreStatutPaiement == '',
                    onTap: () => setState(() => _filtreStatutPaiement = '')),
                _FilterChip(label: 'Payé',   value: 'paye',      selected: _filtreStatutPaiement == 'paye',
                    color: AppTheme.successColor, onTap: () => setState(() => _filtreStatutPaiement = 'paye')),
                _FilterChip(label: 'Non payé',value: 'non_paye', selected: _filtreStatutPaiement == 'non_paye',
                    color: AppTheme.errorColor, onTap: () => setState(() => _filtreStatutPaiement = 'non_paye')),
                _FilterChip(label: 'Partiel', value: 'partiel',  selected: _filtreStatutPaiement == 'partiel',
                    color: AppTheme.warningColor, onTap: () => setState(() => _filtreStatutPaiement = 'partiel')),
              ]),
              const SizedBox(height: 14),

              // Filtre statut transport
              const Text('Statut', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _FilterChip(label: 'Tous', value: '', selected: _filtreStatut == '',
                    onTap: () => setState(() => _filtreStatut = '')),
                _FilterChip(label: 'En attente', value: 'pending', selected: _filtreStatut == 'pending',
                    color: AppTheme.warningColor, onTap: () => setState(() => _filtreStatut = 'pending')),
                _FilterChip(label: 'En cours', value: 'in_progress', selected: _filtreStatut == 'in_progress',
                    color: AppTheme.primaryColor, onTap: () => setState(() => _filtreStatut = 'in_progress')),
                _FilterChip(label: 'Terminé', value: 'completed', selected: _filtreStatut == 'completed',
                    color: AppTheme.successColor, onTap: () => setState(() => _filtreStatut = 'completed')),
              ]),
              const SizedBox(height: 14),

              // Filtre camion
              const Text('Camion', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              trucksAsync.when(
                loading: () => const LinearProgressIndicator(color: AppTheme.primaryColor),
                error: (_, __) => const SizedBox.shrink(),
                data: (trucks) => DropdownButtonFormField<int?>(
                  value: _filtreTruckId,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les camions')),
                    ...trucks.map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text('${t.plateNumber} — ${t.brand} ${t.model}', overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) => setState(() {
                    _filtreTruckId    = v;
                    _filtreTruckLabel = v == null ? 'Tous les camions'
                        : trucks.firstWhere((t) => t.id == v).plateNumber;
                  }),
                ),
              ),
            ]),
          ),
        ),

        // ── Résumé financier ────────────────────────────────────────────────
        transportsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (transports) {
            if (transports.isEmpty) return const SizedBox.shrink();
            final fmt = NumberFormat('#,###', 'fr_FR');
            final total    = transports.fold<double>(0, (s, t) => s + (t.montantTransport ?? 0));
            final paye     = transports.where((t) => t.statutPaiement == 'paye').fold<double>(0, (s, t) => s + (t.montantPaye ?? 0));
            final nonPaye  = total - paye;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(children: [
                _StatBox(label: 'Total',     value: '${fmt.format(total)} F',    color: Colors.white),
                _StatBox(label: 'Payé',    value: '${fmt.format(paye)} F',     color: AppTheme.successColor),
                _StatBox(label: 'Non payé',value: '${fmt.format(nonPaye)} F',  color: AppTheme.errorColor),
                _StatBox(label: 'Voyages',   value: '${transports.length}',      color: Colors.white),
              ]),
            );
          },
        ),

        // ── Liste transports ────────────────────────────────────────────────
        Expanded(
          child: transportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.errorColor.withOpacity(0.1)),
                child: const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                onPressed: () => ref.invalidate(transportsProvider(_queryString)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ])),
            data: (transports) => transports.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
                      child: Icon(Icons.route_rounded, size: 48, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 20),
                    Text(_hasFilter ? 'Aucun transport pour ce filtre' : 'Aucun transport',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                    if (_hasFilter) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Effacer les filtres'),
                        onPressed: _resetFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ]))
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: () async => ref.invalidate(transportsProvider(_queryString)),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: transports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _TransportCard(
                        transport: transports[i],
                        onTap: () => context.push('/transports/detail/${transports[i].id}'),
                        onStatusChange: (s) => ref.read(transportsProvider(_queryString).notifier).updateStatus(transports[i].id, s),
                        onPaiementChange: (s, {double? montant}) => ref.read(transportsProvider(_queryString).notifier).updatePaiement(
                            transports[i].id, s, montantTransport: montant),
                      ),
                    ),
                  ),
          ),
        ),
      ]),

      // FAB supprimé — bouton "Nouveau" intégré dans l'AppBar
    );
  }
}

// ── Widgets helpers ──────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : Colors.white,
          border: Border.all(color: selected ? c : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? c : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _PaiementBadge extends StatelessWidget {
  final String statut;
  const _PaiementBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color color; String label;
    switch (statut) {
      case 'paye':    color = AppTheme.successColor; label = 'Payé';     break;
      case 'partiel': color = AppTheme.warningColor;         label = 'Partiel';  break;
      default:        color = AppTheme.errorColor;   label = 'Non payé'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _TransportCard extends StatelessWidget {
  final TransportModel transport;
  final VoidCallback onTap;
  final void Function(String) onStatusChange;
  final void Function(String, {double? montant}) onPaiementChange;
  const _TransportCard({required this.transport, required this.onTap,
      required this.onStatusChange, required this.onPaiementChange});

  @override
  Widget build(BuildContext context) {
    final fmt         = NumberFormat('#,###', 'fr_FR');
    final statusColor = AppTheme.statusColor(transport.status);
    final statusLabel = AppConstants.transportStatuses[transport.status] ?? transport.status;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header : référence + statut + actions ─────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.12), statusColor.withOpacity(0.03)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              // Icône statut
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(transport.status), color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(transport.reference,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.35)),
                    ),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey[500]),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'paye',
                      child: ListTile(dense: true, leading: Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
                          title: Text('Marquer payé', style: TextStyle(fontWeight: FontWeight.w600)))),
                  const PopupMenuItem(value: 'non_paye',
                      child: ListTile(dense: true, leading: Icon(Icons.cancel_rounded, color: AppTheme.errorColor),
                          title: Text('Marquer non payé', style: TextStyle(fontWeight: FontWeight.w600)))),
                  const PopupMenuItem(value: 'partiel',
                      child: ListTile(dense: true, leading: Icon(Icons.schedule_rounded, color: AppTheme.warningColor),
                          title: Text('Paiement partiel', style: TextStyle(fontWeight: FontWeight.w600)))),
                  const PopupMenuDivider(),
                  if (transport.isPending)
                    const PopupMenuItem(value: 'in_progress',
                        child: ListTile(dense: true, leading: Icon(Icons.play_arrow_rounded, color: AppTheme.primaryColor),
                            title: Text('Démarrer', style: TextStyle(fontWeight: FontWeight.w600)))),
                  if (transport.isInProgress)
                    const PopupMenuItem(value: 'completed',
                        child: ListTile(dense: true, leading: Icon(Icons.check_rounded, color: AppTheme.successColor),
                            title: Text('Terminer', style: TextStyle(fontWeight: FontWeight.w600)))),
                ],
                onSelected: (s) {
                  if (s == 'paye' || s == 'non_paye' || s == 'partiel') {
                    onPaiementChange(s);
                  } else {
                    onStatusChange(s);
                  }
                },
              ),
            ]),
          ),

          // ── Corps : trajet + infos ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Trajet avec ligne verticale
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Ligne + points
                  Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.successColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)])),
                    Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(gradient: LinearGradient(
                          colors: [AppTheme.successColor, AppTheme.errorColor],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ), borderRadius: BorderRadius.circular(1)))),
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.errorColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)])),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Départ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        Text(transport.origin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ]),
                      const SizedBox(height: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Arrivée', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        Text(transport.destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 14),

              // Infos : camion + client
              Row(children: [
                if (transport.truck != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.local_shipping_rounded, size: 13, color: Colors.blueGrey.shade600),
                      const SizedBox(width: 5),
                      Text(transport.truck!.plateNumber,
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                ],
                if (transport.clientName != null)
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.business_rounded, size: 13, color: Colors.purple.shade400),
                      const SizedBox(width: 5),
                      Expanded(child: Text(transport.clientName!,
                          style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
              ]),
            ]),
          ),

          // ── Footer : montant + paiement ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(children: [
              Text(
                '${fmt.format(transport.montantTransport ?? 0)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryColor),
              ),
              const Spacer(),
              _PaiementBadge(statut: transport.statutPaiement ?? 'non_paye'),
            ]),
          ),
        ]),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'in_progress': return Icons.play_circle_filled_rounded;
      case 'completed':   return Icons.check_circle_rounded;
      case 'cancelled':   return Icons.cancel_rounded;
      case 'delayed':     return Icons.warning_rounded;
      default:            return Icons.access_time_rounded;
    }
  }
}
