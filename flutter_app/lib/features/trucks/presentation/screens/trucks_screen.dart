import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trucks_provider.dart';
import '../../../auth/data/models/truck_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class TrucksScreen extends ConsumerStatefulWidget {
  const TrucksScreen({super.key});
  @override
  ConsumerState<TrucksScreen> createState() => _TrucksScreenState();
}

class _TrucksScreenState extends ConsumerState<TrucksScreen> {
  final _searchCtrl = TextEditingController();
  String _search    = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(trucksProvider(_search));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Camions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showTruckDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un camion...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                  : null,
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: trucksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              const Text('Impossible de charger', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(trucksProvider(_search)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ])),
            data: (trucks) => trucks.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.local_shipping_rounded, size: 64, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text('Aucun camion trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('Ajoutez votre premier camion', style: TextStyle(color: AppTheme.textSecondary)),
                  ]))
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(trucksProvider(_search)),
                    color: AppTheme.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: trucks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _TruckCard(
                        truck: trucks[i],
                        onStatusChange: (s) => ref.read(trucksProvider(_search).notifier).updateStatus(trucks[i].id, s),
                        onDelete: () => _confirmDelete(context, trucks[i]),
                        onEdit: () => _showTruckDialog(context, truck: trucks[i]),
                      ),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  void _showTruckDialog(BuildContext context, {TruckModel? truck}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TruckFormSheet(
        truck: truck,
        onSave: (data) async {
          if (truck == null) {
            await ref.read(trucksProvider(_search).notifier).createTruck(data);
          } else {
            await ref.read(trucksProvider(_search).notifier).updateTruck(truck.id, data);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, TruckModel truck) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Supprimer le camion'),
      content: Text('Supprimer ${truck.plateNumber} ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(trucksProvider(_search).notifier).deleteTruck(truck.id);
          },
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }
}

class _TruckCard extends StatelessWidget {
  final TruckModel truck;
  final void Function(String) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _TruckCard({required this.truck, required this.onStatusChange, required this.onDelete, required this.onEdit});

  // Détermine le vrai statut à afficher : priorité au transport actif
  bool get _isOnTrip => truck.activeTransport != null;

  Color get _statusBgColor {
    if (_isOnTrip) return const Color(0xFFFFF7ED); // orange clair
    switch (truck.status) {
      case 'available':      return const Color(0xFFF0FDF4); // vert très clair
      case 'maintenance':    return const Color(0xFFFFFBEB); // jaune clair
      case 'out_of_service': return const Color(0xFFFFF1F2); // rouge clair
      default:               return const Color(0xFFF0F4FF); // bleu clair
    }
  }

  Color get _statusDotColor {
    if (_isOnTrip) return const Color(0xFFEA580C);
    switch (truck.status) {
      case 'available':      return const Color(0xFF16A34A);
      case 'maintenance':    return const Color(0xFFD97706);
      case 'out_of_service': return const Color(0xFFDC2626);
      default:               return const Color(0xFF2563EB);
    }
  }

  Color get _statusTextColor {
    if (_isOnTrip) return const Color(0xFF9A3412);
    switch (truck.status) {
      case 'available':      return const Color(0xFF15803D);
      case 'maintenance':    return const Color(0xFF92400E);
      case 'out_of_service': return const Color(0xFFB91C1C);
      default:               return const Color(0xFF1D4ED8);
    }
  }

  String get _statusLabel {
    if (_isOnTrip) {
      final dest = truck.activeTransport!['destination'] as String? ?? '?';
      return 'En voyage → $dest';
    }
    switch (truck.status) {
      case 'available':      return 'Disponible';
      case 'maintenance':    return 'Maintenance';
      case 'out_of_service': return 'Hors service';
      case 'on_mission':     return 'En mission';
      default:               return truck.status;
    }
  }

  IconData get _statusIcon {
    if (_isOnTrip) return Icons.local_shipping_rounded;
    switch (truck.status) {
      case 'available':      return Icons.check_circle_rounded;
      case 'maintenance':    return Icons.build_rounded;
      case 'out_of_service': return Icons.cancel_rounded;
      default:               return Icons.local_shipping_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/trucks/detail/${truck.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.subtleShadow,
          border: Border.all(
            color: _isOnTrip
                ? const Color(0xFFFBD38D)
                : truck.status == 'available'
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header : fond blanc, plaque + marque ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(children: [
              // Icône camion avec couleur statut
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusDotColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon, color: _statusDotColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(truck.plateNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17,
                      color: AppTheme.textPrimary, letterSpacing: -0.3,
                    )),
                Text('${truck.brand} ${truck.model} · ${truck.year}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              // Menu actions
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 18),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Row(children: [
                    Container(padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 16)),
                    const SizedBox(width: 10),
                    const Text('Modifier', style: TextStyle(fontWeight: FontWeight.w600)),
                  ])),
                  PopupMenuItem(value: 'delete', child: Row(children: [
                    Container(padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.error.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 16)),
                    const SizedBox(width: 10),
                    const Text('Supprimer', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                  ])),
                  const PopupMenuDivider(),
                  ...AppConstants.truckStatuses.entries.map((e) =>
                    PopupMenuItem(value: 'status_${e.key}', child: Row(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: AppTheme.statusColor(e.key), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]))),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  else if (v == 'delete') onDelete();
                  else if (v.startsWith('status_')) onStatusChange(v.substring(7));
                },
              ),
            ]),
          ),

          // ── Divider ───────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // ── Statut principal très visible ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _statusBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusDotColor.withAlpha(60), width: 1),
              ),
              child: Row(children: [
                // Point clignotant simulé avec double cercle
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _statusDotColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _statusDotColor.withAlpha(80), blurRadius: 6, spreadRadius: 2)],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _statusTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isOnTrip)
                  Icon(Icons.chevron_right_rounded, color: _statusDotColor, size: 18),
              ]),
            ),
          ),

          // ── Détail voyage si en voyage ────────────────────────────
          if (_isOnTrip)
            _TripBanner(transport: truck.activeTransport!),

          // ── Infos propriétaire + chips ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (truck.proprietaire != null && truck.proprietaire!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.person_rounded, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(truck.proprietaire!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    if (truck.villeActuelle != null && truck.villeActuelle!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(width: 3, height: 3,
                          decoration: const BoxDecoration(color: AppTheme.textHint, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Expanded(child: Text(truck.villeActuelle!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                ),
              Row(children: [
                _Chip(icon: Icons.scale_rounded, label: '${truck.capacity}t', color: AppTheme.primary),
                const SizedBox(width: 6),
                _Chip(icon: Icons.local_gas_station_rounded, label: truck.fuelType, color: AppTheme.accent),
                const SizedBox(width: 6),
                _Chip(icon: Icons.speed_rounded, label: '${truck.mileage} km', color: AppTheme.info),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Widget détail voyage ──────────────────────────────────────────────────────
class _TripBanner extends StatelessWidget {
  final Map<String, dynamic> transport;
  const _TripBanner({required this.transport});

  String _formatDate(String? raw) {
    if (raw == null) return '?';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} à ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin      = (transport['origin']      as String?) ?? '—';
    final destination = (transport['destination'] as String?) ?? '—';
    final status      = (transport['status']       as String?) ?? '';
    final clientName  = transport['client_name']  as String?;
    final reference   = transport['reference']    as String?;
    final departure   = _formatDate(
      transport['actual_departure'] as String? ?? transport['scheduled_departure'] as String?,
    );
    final arrivalRaw  = transport['actual_arrival'] as String?;
    final isReturned  = arrivalRaw != null;
    final isInProgress = status == 'in_progress';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Fond sombre contrasté pour bien ressortir
        color: isReturned
            ? const Color(0xFFECFDF5)
            : const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Ligne itinéraire principale ──────────────────────────────
        Row(children: [
          // Point de départ
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isReturned ? const Color(0xFF16A34A) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              origin,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isReturned ? const Color(0xFF15803D) : Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: isReturned ? const Color(0xFF16A34A) : const Color(0xFFFBBF24),
            ),
          ),
          // Point d'arrivée
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isReturned ? const Color(0xFF16A34A) : const Color(0xFFFBBF24),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              destination,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isReturned ? const Color(0xFF15803D) : const Color(0xFFFBBF24),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),

        const SizedBox(height: 8),

        // ── Ligne départ ─────────────────────────────────────────────
        Row(children: [
          Icon(
            Icons.flight_takeoff_rounded, size: 12,
            color: isReturned ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 6),
          Text(
            'Départ : $departure',
            style: TextStyle(
              fontSize: 11,
              color: isReturned ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
            ),
          ),
        ]),

        // ── Ligne retour si revenu ───────────────────────────────────
        if (isReturned) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.flight_land_rounded, size: 12, color: Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Text(
              'Retour : ${_formatDate(arrivalRaw)}',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D),
              ),
            ),
          ]),
        ] else ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(
              isInProgress ? 'Retour non confirmé' : 'Départ planifié',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ]),
        ],

        // ── Client + Référence ───────────────────────────────────────
        if (clientName != null || reference != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: isReturned ? const Color(0xFFD1FAE5) : const Color(0xFF374151),
          ),
          const SizedBox(height: 8),
          Row(children: [
            if (clientName != null) ...[
              Icon(Icons.business_rounded, size: 11,
                  color: isReturned ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Flexible(child: Text(clientName,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isReturned ? const Color(0xFF374151) : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis)),
            ],
            if (clientName != null && reference != null) const SizedBox(width: 10),
            if (reference != null) ...[
              Icon(Icons.tag_rounded, size: 11,
                  color: isReturned ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(reference,
                  style: TextStyle(
                    fontSize: 11,
                    color: isReturned ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  )),
            ],
          ]),
        ],
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: Colors.grey[600]),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
  ]);
}

class _TruckFormSheet extends StatefulWidget {
  final TruckModel? truck;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _TruckFormSheet({this.truck, required this.onSave});
  @override
  State<_TruckFormSheet> createState() => _TruckFormSheetState();
}

class _TruckFormSheetState extends State<_TruckFormSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _plateCtrl          = TextEditingController();
  final _brandCtrl          = TextEditingController();
  final _modelCtrl          = TextEditingController();
  final _yearCtrl           = TextEditingController();
  final _capCtrl            = TextEditingController();
  final _colorCtrl          = TextEditingController();
  final _vinCtrl            = TextEditingController();
  final _mileageCtrl        = TextEditingController();
  final _proprietaireCtrl   = TextEditingController();
  final _telephoneCtrl      = TextEditingController();
  final _villeCtrl          = TextEditingController();
  final _insuranceExpiryCtrl         = TextEditingController();
  final _technicalControlExpiryCtrl  = TextEditingController();
  final _notesCtrl          = TextEditingController();
  String _fuelType  = 'diesel';
  String _type      = 'flatbed';
  bool _isLoading   = false;

  @override
  void initState() {
    super.initState();
    if (widget.truck != null) {
      _plateCtrl.text = widget.truck!.plateNumber;
      _brandCtrl.text = widget.truck!.brand;
      _modelCtrl.text = widget.truck!.model;
      _yearCtrl.text  = widget.truck!.year.toString();
      _capCtrl.text   = widget.truck!.capacity.toString();
      _colorCtrl.text = widget.truck!.color ?? '';
      _vinCtrl.text = widget.truck!.vin ?? '';
      _mileageCtrl.text = widget.truck!.mileage.toString();
      _insuranceExpiryCtrl.text = widget.truck!.insuranceExpiry ?? '';
      _technicalControlExpiryCtrl.text = widget.truck!.technicalControlExpiry ?? '';
      _notesCtrl.text = widget.truck!.notes ?? '';
      _fuelType                       = widget.truck!.fuelType;
      _type                           = widget.truck!.type;
      _proprietaireCtrl.text          = widget.truck!.proprietaire ?? '';
      _telephoneCtrl.text             = widget.truck!.telephoneProprietaire ?? '';
      _villeCtrl.text                 = widget.truck!.villeActuelle ?? '';
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _capCtrl.dispose();
    _colorCtrl.dispose();
    _vinCtrl.dispose();
    _mileageCtrl.dispose();
    _proprietaireCtrl.dispose();
    _telephoneCtrl.dispose();
    _villeCtrl.dispose();
    _insuranceExpiryCtrl.dispose();
    _technicalControlExpiryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _truckTypeLabels = {
    'flatbed': 'Plateau',
    'refrigerated': 'Frigorifique',
    'tanker': 'Citerne',
    'container': 'Conteneur',
    'curtain': 'Bachée',
    'tipper': 'Benne',
    'van': 'Fourgon',
  };

  Map<String, String> _fuelTypeLabels = {
    'diesel': 'Diesel',
    'petrol': 'Essence',
    'electric': 'Électrique',
    'hybrid': 'Hybride',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.truck == null ? 'Ajouter un camion' : 'Modifier le camion',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(controller: _plateCtrl, decoration: const InputDecoration(labelText: 'Immatriculation'), validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Marque'), validator: (v) => v!.isEmpty ? 'Requis' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _modelCtrl, decoration: const InputDecoration(labelText: 'Modèle'), validator: (v) => v!.isEmpty ? 'Requis' : null)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Année'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requis' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _capCtrl, decoration: const InputDecoration(labelText: 'Capacité (t)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requis' : null)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type, decoration: const InputDecoration(labelText: 'Type'),
            items: _truckTypeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _fuelType, decoration: const InputDecoration(labelText: 'Carburant'),
            items: _fuelTypeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _fuelType = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Couleur')),
          const SizedBox(height: 12),
          TextFormField(controller: _vinCtrl, decoration: const InputDecoration(labelText: 'Numéro de châssis (VIN)')),
          const SizedBox(height: 12),
          TextFormField(controller: _mileageCtrl, decoration: const InputDecoration(labelText: 'Kilométrage'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextFormField(
            controller: _insuranceExpiryCtrl,
            decoration: const InputDecoration(labelText: 'Expiration assurance (yyyy-MM-dd)'),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2040));
              if (date != null) _insuranceExpiryCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _technicalControlExpiryCtrl,
            decoration: const InputDecoration(labelText: 'Expiration visite technique (yyyy-MM-dd)'),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2040));
              if (date != null) _technicalControlExpiryCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 24),
          const Text('👤 Propriétaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _proprietaireCtrl,
            decoration: const InputDecoration(labelText: 'Nom du propriétaire', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telephoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Téléphone propriétaire', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _villeCtrl,
            decoration: const InputDecoration(labelText: 'Ville actuelle du camion', prefixIcon: Icon(Icons.location_city_outlined)),
          ),
          const Divider(height: 24),
          TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              if (!_formKey.currentState!.validate()) return;
              setState(() => _isLoading = true);
              try {
                final data = {
                  'plate_number': _plateCtrl.text, 'brand': _brandCtrl.text,
                  'model': _modelCtrl.text, 'year': int.parse(_yearCtrl.text),
                  'capacity': double.parse(_capCtrl.text), 'type': _type, 'fuel_type': _fuelType,
                };
                if (_colorCtrl.text.isNotEmpty) data['color'] = _colorCtrl.text;
                if (_vinCtrl.text.isNotEmpty) data['vin'] = _vinCtrl.text;
                if (_mileageCtrl.text.isNotEmpty) data['mileage'] = int.parse(_mileageCtrl.text);
                if (_insuranceExpiryCtrl.text.isNotEmpty) data['insurance_expiry'] = _insuranceExpiryCtrl.text;
                if (_technicalControlExpiryCtrl.text.isNotEmpty) data['technical_control_expiry'] = _technicalControlExpiryCtrl.text;
                if (_notesCtrl.text.isNotEmpty)          data['notes']                   = _notesCtrl.text;
                if (_proprietaireCtrl.text.isNotEmpty)   data['proprietaire']             = _proprietaireCtrl.text;
                if (_telephoneCtrl.text.isNotEmpty)      data['telephone_proprietaire']   = _telephoneCtrl.text;
                if (_villeCtrl.text.isNotEmpty)          data['ville_actuelle']           = _villeCtrl.text;
                await widget.onSave(data);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'), backgroundColor: AppTheme.errorColor));
              } finally { if (mounted) setState(() => _isLoading = false); }
            },
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.truck == null ? 'Ajouter' : 'Modifier'),
          ),
          const SizedBox(height: 16),
        ])),
      ),
    );
  }
}
