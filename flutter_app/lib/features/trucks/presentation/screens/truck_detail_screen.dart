import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/models/truck_model.dart';
import '../../../auth/data/models/operation_model.dart';
import '../../../auth/data/models/document_model.dart';
import '../../../auth/data/models/transport_model.dart';
import '../../../../core/network/api_client.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final truckDetailProvider = FutureProvider.family<TruckModel, int>((ref, truckId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/trucks/$truckId');
  final data = response.data as Map<String, dynamic>;
  return TruckModel.fromJson(data['truck'] as Map<String, dynamic>);
});

final truckOperationsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, truckId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/operations', params: {'truck_id': truckId, 'per_page': 50});
  final data = response.data as Map<String, dynamic>;
  final list = (data['operations'] as List? ?? [])
      .map((e) => OperationModel.fromJson(e as Map<String, dynamic>))
      .toList();
  final totaux = data['totaux'] as Map<String, dynamic>? ?? {};
  return {'operations': list, 'totaux': totaux};
});

final truckDocumentsProvider = FutureProvider.family<List<DocumentModel>, int>((ref, truckId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/documents', params: {'truck_id': truckId});
  final data = response.data;
  final list = (data is Map ? (data['documents'] ?? data['data'] ?? []) : data) as List;
  return list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
});

final truckTransportsProvider = FutureProvider.family<List<TransportModel>, int>((ref, truckId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/transports', params: {'truck_id': truckId, 'per_page': 50});
  final data = response.data as Map<String, dynamic>;
  final list = (data['data'] as List? ?? []);
  return list.map((e) => TransportModel.fromJson(e as Map<String, dynamic>)).toList();
});

// ============================================================================
// MAIN SCREEN
// ============================================================================

class TruckDetailScreen extends ConsumerWidget {
  final int truckId;

  const TruckDetailScreen({
    Key? key,
    required this.truckId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Détail du Camion',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                TabBar(
                  labelColor: const Color(0xFF1B4FD8),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF1B4FD8),
                  indicatorWeight: 3,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(color: Color(0xFF1B4FD8), width: 3),
                    insets: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(Icons.info_rounded, size: 20), text: 'Infos'),
                    Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'Chauffeur'),
                    Tab(icon: Icon(Icons.trending_up_rounded, size: 20), text: 'Opérations'),
                    Tab(icon: Icon(Icons.description_rounded, size: 20), text: 'Documents'),
                    Tab(icon: Icon(Icons.map_rounded, size: 20), text: 'Transports'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _InfoTab(truckId: truckId),
            _DriverTab(truckId: truckId),
            _OperationsTab(truckId: truckId),
            _DocumentsTab(truckId: truckId),
            _TransportsTab(truckId: truckId),
          ],
        ),
      ),
    );
  }
}

// ── Bouton confirmer retour ───────────────────────────────────────────────────
class _ConfirmRetourButton extends ConsumerStatefulWidget {
  final int transportId;
  final int truckId;
  const _ConfirmRetourButton({required this.transportId, required this.truckId});

  @override
  ConsumerState<_ConfirmRetourButton> createState() => _ConfirmRetourButtonState();
}

class _ConfirmRetourButtonState extends ConsumerState<_ConfirmRetourButton> {
  bool _loading = false;

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.flight_land_rounded, color: Color(0xFF16A34A)),
          SizedBox(width: 10),
          Text('Confirmer le retour', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'Le camion est bien de retour à la base ?\nLe transport sera marqué comme terminé.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(0, 42),
            ),
            child: const Text('✅ Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/transports/${widget.transportId}/retour');
      if (mounted) {
        ref.invalidate(truckDetailProvider(widget.truckId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Retour confirmé ! Camion disponible.', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _confirm,
        icon: _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.flight_land_rounded, size: 18),
        label: Text(_loading ? 'Confirmation...' : 'Confirmer le retour'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          minimumSize: const Size(0, 48),
        ),
      ),
    );
  }
}

// ============================================================================
// INFO TAB
// ============================================================================

class _InfoTab extends ConsumerWidget {
  final int truckId;

  const _InfoTab({required this.truckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truckAsync = ref.watch(truckDetailProvider(truckId));

    return truckAsync.when(
      data: (truck) => _buildInfoContent(context, truck),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4FD8))),
      error: (err, stack) => _buildErrorState('Erreur de chargement'),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEDED),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContent(BuildContext context, TruckModel truck) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image Card
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: truck.photo != null
                  ? Image.network(truck.photo!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B4FD8), Color(0xFF3B6EF0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.local_shipping_rounded, size: 96, color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),

          // Truck Name & Type
          Text(
            truck.displayName,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${truck.type} • ${truck.brand} ${truck.model}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Status Badges Row
          Row(
            children: [
              Expanded(
                child: _buildStatusBadge(
                  'Assurance',
                  truck.insuranceStatus ?? 'unknown',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusBadge(
                  'Visite Tech.',
                  truck.technicalControlExpiry != null ? 'Valide' : 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Statut voyage en cours ──────────────────────────────────
          _buildTripStatusCard(truck),
          const SizedBox(height: 24),

          // Main Info Card
          _buildSectionTitle('Informations Principales'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow('Immatriculation', truck.plateNumber, Icons.badge_rounded, 0),
                _buildDivider(),
                _buildInfoRow('Année', truck.year.toString(), Icons.calendar_month_rounded, 1),
                _buildDivider(),
                _buildInfoRow('Capacité', '${truck.capacity} tonnes', Icons.scale_rounded, 2),
                _buildDivider(),
                _buildInfoRow('Carburant', truck.fuelType, Icons.local_gas_station_rounded, 3),
                _buildDivider(),
                _buildInfoRow('Kilométrage', '${truck.mileage} km', Icons.speed_rounded, 4),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Specs Card
          _buildSectionTitle('Spécifications'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow('Marque', truck.brand, Icons.business_center_rounded, 0),
                _buildDivider(),
                _buildInfoRow('Modèle', truck.model, Icons.directions_car_rounded, 1),
                if (truck.color != null) ...[
                  _buildDivider(),
                  _buildInfoRow('Couleur', truck.color!, Icons.palette_rounded, 2),
                ],
                if (truck.vin != null) ...[
                  _buildDivider(),
                  _buildInfoRow('VIN', truck.vin!, Icons.fingerprint_rounded, 3),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notes Section
          if (truck.notes != null && truck.notes!.isNotEmpty) ...[
            _buildSectionTitle('Notes'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                truck.notes!,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ── Carte statut voyage ────────────────────────────────────────────────────
  Widget _buildTripStatusCard(TruckModel truck) {
    final trip = truck.activeTransport;
    final isOnTrip = trip != null;

    if (!isOnTrip) {
      // Camion disponible ou autre statut
      final (Color bg, Color dot, Color text, IconData icon, String label) = switch (truck.status) {
        'available'      => (const Color(0xFFF0FDF4), const Color(0xFF16A34A), const Color(0xFF15803D), Icons.check_circle_rounded, 'Disponible — Aucun voyage en cours'),
        'maintenance'    => (const Color(0xFFFFFBEB), const Color(0xFFD97706), const Color(0xFF92400E), Icons.build_rounded, 'En maintenance'),
        'out_of_service' => (const Color(0xFFFFF1F2), const Color(0xFFDC2626), const Color(0xFFB91C1C), Icons.cancel_rounded, 'Hors service'),
        _                => (const Color(0xFFF0F4FF), const Color(0xFF2563EB), const Color(0xFF1D4ED8), Icons.local_shipping_rounded, 'En mission'),
      };
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dot.withAlpha(60)),
        ),
        child: Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: dot, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dot.withAlpha(80), blurRadius: 6, spreadRadius: 2)],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: dot, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
        ]),
      );
    }

    // En voyage
    String _fmt(String? raw) {
      if (raw == null) return '?';
      try {
        final dt = DateTime.parse(raw).toLocal();
        return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} à ${dt.hour.toString().padLeft(2,'0')}h${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) { return raw; }
    }

    final origin      = (trip['origin']      as String?) ?? '—';
    final destination = (trip['destination'] as String?) ?? '—';
    final clientName  = trip['client_name']  as String?;
    final reference   = trip['reference']    as String?;
    final departure   = _fmt(trip['actual_departure'] as String? ?? trip['scheduled_departure'] as String?);
    final arrivalRaw  = trip['actual_arrival'] as String?;
    final isReturned  = arrivalRaw != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isReturned ? const Color(0xFFECFDF5) : const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isReturned ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(
              isReturned ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              isReturned ? 'Voyage terminé' : '🚛  En voyage actuellement',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ]),
        ),
        // Corps
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Itinéraire
            Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: isReturned ? const Color(0xFF16A34A) : Colors.white,
                    shape: BoxShape.circle,
                  )),
              const SizedBox(width: 10),
              Flexible(child: Text(origin,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isReturned ? const Color(0xFF15803D) : Colors.white),
                  overflow: TextOverflow.ellipsis)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, size: 18,
                    color: isReturned ? const Color(0xFF16A34A) : const Color(0xFFFBBF24)),
              ),
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: isReturned ? const Color(0xFF16A34A) : const Color(0xFFFBBF24),
                    shape: BoxShape.circle,
                  )),
              const SizedBox(width: 10),
              Flexible(child: Text(destination,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: isReturned ? const Color(0xFF15803D) : const Color(0xFFFBBF24)),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            // Dates
            _detailRow(Icons.flight_takeoff_rounded, 'Départ', departure, isReturned),
            const SizedBox(height: 6),
            _detailRow(
              isReturned ? Icons.flight_land_rounded : Icons.hourglass_top_rounded,
              isReturned ? 'Retour' : 'Retour',
              isReturned ? _fmt(arrivalRaw) : 'Non confirmé',
              isReturned,
              highlight: isReturned,
            ),
            if (clientName != null || reference != null) ...[
              const SizedBox(height: 12),
              Container(height: 1,
                  color: isReturned ? const Color(0xFFD1FAE5) : const Color(0xFF374151)),
              const SizedBox(height: 12),
              if (clientName != null)
                _detailRow(Icons.business_rounded, 'Client', clientName, isReturned),
              if (reference != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.tag_rounded, 'Référence', reference, isReturned),
              ],
            ],
            // ── Bouton confirmer retour ────────────────────────────
            if (!isReturned) ...[
              const SizedBox(height: 14),
              _ConfirmRetourButton(
                transportId: trip['id'] as int,
                truckId: truckId,
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isReturned, {bool highlight = false}) {
    final labelColor = isReturned ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final valueColor = highlight
        ? const Color(0xFF15803D)
        : isReturned ? const Color(0xFF111827) : Colors.white;
    return Row(children: [
      Icon(icon, size: 14, color: labelColor),
      const SizedBox(width: 8),
      Text('$label : ', style: TextStyle(fontSize: 13, color: labelColor)),
      Flexible(child: Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
          overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4FD8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1B4FD8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: const Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }

  Widget _buildStatusBadge(String label, String status) {
    Color badgeColor;
    Color backgroundColor;
    IconData icon;

    if (status.toLowerCase().contains('valide') || status.toLowerCase().contains('valid')) {
      badgeColor = const Color(0xFF10B981);
      backgroundColor = const Color(0xFFD1FAE5);
      icon = Icons.check_circle_rounded;
    } else if (status.toLowerCase().contains('expir')) {
      badgeColor = const Color(0xFFEF4444);
      backgroundColor = const Color(0xFFFFEDED);
      icon = Icons.cancel_rounded;
    } else if (status.toLowerCase().contains('soon')) {
      badgeColor = const Color(0xFFF59E0B);
      backgroundColor = const Color(0xFFFEF3C7);
      icon = Icons.warning_rounded;
    } else {
      badgeColor = const Color(0xFF64748B);
      backgroundColor = const Color(0xFFF1F5F9);
      icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: badgeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DRIVER TAB
// ============================================================================

class _DriverTab extends ConsumerWidget {
  final int truckId;
  const _DriverTab({required this.truckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truckAsync = ref.watch(truckDetailProvider(truckId));
    return truckAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4FD8))),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFEDED),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      data: (truck) {
        final driver = truck.driver;
        if (driver == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0E7FF),
                  ),
                  child: const Icon(
                    Icons.person_off_rounded,
                    size: 56,
                    color: Color(0xFF1B4FD8),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun chauffeur assigné',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assignez un chauffeur pour continuer',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Assigner un Chauffeur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4FD8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _assignDriver(context, ref, truck.id),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Card Hero
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4FD8), Color(0xFF3B6EF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4FD8).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${(driver['first_name'] as String? ?? 'C')[0]}${(driver['last_name'] as String? ?? 'H')[0]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      '${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Status Badge
                    _StatusBadge(status: driver['status'] ?? 'available'),
                    const SizedBox(height: 16),
                    // Details Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                        label: const Text(
                          'Voir le profil complet',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => context.push('/drivers/${driver['id']}'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Contact & License Info
              _buildSectionTitle('Informations'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDriverInfoRow('Téléphone', driver['phone'] ?? '—', Icons.phone_rounded, 0),
                    _buildDriverDivider(),
                    _buildDriverInfoRow('Permis N°', driver['license_number'] ?? '—', Icons.credit_card_rounded, 1),
                    _buildDriverDivider(),
                    _buildDriverInfoRow('Type de permis', driver['license_type'] ?? '—', Icons.badge_rounded, 2),
                    _buildDriverDivider(),
                    _buildDriverInfoRow('Expiration permis', driver['license_expiry'] ?? '—', Icons.event_rounded, 3),
                    _buildDriverDivider(),
                    _buildDriverInfoRow('Ville', driver['city'] ?? '—', Icons.location_on_rounded, 4),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              _buildSectionTitle('Actions'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1B4FD8)),
                  label: const Text(
                    'Changer de chauffeur',
                    style: TextStyle(color: Color(0xFF1B4FD8)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1B4FD8), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _assignDriver(context, ref, truck.id),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_remove_rounded),
                  label: const Text('Retirer le chauffeur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _removeDriver(context, ref, driver['id'] as int),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4FD8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfoRow(String label, String value, IconData icon, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1B4FD8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: const Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }

  Future<void> _assignDriver(BuildContext context, WidgetRef ref, int truckId) async {
    final api = ref.read(apiClientProvider);
    final resp = await api.get('/drivers', params: {'status': 'available'});
    final drivers = ((resp.data['data'] ?? resp.data['drivers'] ?? []) as List);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sélectionner un chauffeur',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisissez parmi les chauffeurs disponibles',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Drivers List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final d = drivers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          Navigator.pop(context);
                          await api.patch('/drivers/${d['id']}', data: {'current_truck_id': truckId});
                          ref.invalidate(truckDetailProvider(truckId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 12),
                                    Text('Chauffeur assigné'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${d['first_name'][0]}${d['last_name'][0]}',
                                    style: const TextStyle(
                                      color: Color(0xFF1B4FD8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${d['first_name']} ${d['last_name']}',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d['phone'] ?? 'N/A',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeDriver(BuildContext context, WidgetRef ref, int driverId) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/drivers/$driverId', data: {'current_truck_id': null});
    ref.invalidate(truckDetailProvider(truckId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Chauffeur retiré'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final colors = {
      'available': const Color(0xFF10B981),
      'on_mission': const Color(0xFF1B4FD8),
      'on_leave': const Color(0xFFF59E0B),
      'inactive': const Color(0xFF64748B),
    };
    final labels = {
      'available': 'Disponible',
      'on_mission': 'En mission',
      'on_leave': 'En congé',
      'inactive': 'Inactif'
    };
    final color = colors[status] ?? const Color(0xFF64748B);
    final label = labels[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// OPERATIONS TAB
// ============================================================================

class _OperationsTab extends ConsumerWidget {
  final int truckId;

  const _OperationsTab({required this.truckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operationsAsync = ref.watch(truckOperationsProvider(truckId));

    return operationsAsync.when(
      data: (data) {
        final operations = (data['operations'] as List).cast<OperationModel>();
        final totaux = data['totaux'] as Map<String, dynamic>;
        final totalRecettes = (totaux['recettes'] as num?)?.toDouble() ?? 0.0;
        final totalDepenses = (totaux['depenses'] as num?)?.toDouble() ?? 0.0;
        final benefice = totalRecettes - totalDepenses;
        return _buildOperationsContent(context, operations, totalRecettes, totalDepenses, benefice);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4FD8))),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFEDED),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsContent(BuildContext context, List<OperationModel> operations,
      double totalRecettes, double totalDepenses, double benefice) {
    if (operations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0E7FF),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: Color(0xFF1B4FD8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune opération',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aucune opération enregistrée pour ce camion',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Financial Summary Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4FD8), Color(0xFF3B6EF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4FD8).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Recettes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Recettes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalRecettes.toStringAsFixed(0)} XOF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                const SizedBox(height: 20),

                // Dépenses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.trending_down_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Dépenses',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalDepenses.toStringAsFixed(0)} XOF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                const SizedBox(height: 20),

                // Bénéfice
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                benefice >= 0
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Bénéfice',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${benefice.toStringAsFixed(0)} XOF',
                          style: TextStyle(
                            color: benefice >= 0
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFFEDED),
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Operations List Header
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4FD8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Opérations',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${operations.length} opération${operations.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Operations List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final op = operations[index];
              final isRecette = op.isRecette;
              final color = isRecette
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444);
              final backgroundColor = isRecette
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFFEDED);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: color, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isRecette
                                  ? Icons.add_circle_rounded
                                  : Icons.remove_circle_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  op.designation,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  op.categorie,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isRecette ? '+' : '−'}${op.montant.toStringAsFixed(0)} XOF',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.parse(op.date)),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (op.notes != null && op.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            op.notes!,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ============================================================================
// DOCUMENTS TAB
// ============================================================================

class _DocumentsTab extends ConsumerWidget {
  final int truckId;

  const _DocumentsTab({required this.truckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(truckDocumentsProvider(truckId));

    return documentsAsync.when(
      data: (documents) => _buildDocumentsContent(context, documents),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4FD8))),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFEDED),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsContent(BuildContext context, List<DocumentModel> documents) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0E7FF),
              ),
              child: const Icon(
                Icons.description_rounded,
                size: 56,
                color: Color(0xFF1B4FD8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun document',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aucun document enregistré pour ce camion',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final statusInfo = _getStatusInfo(doc.status ?? 'unknown');

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // File Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: statusInfo['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc.typeLabel,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'] as Color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (statusInfo['color'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusInfo['label'] as String,
                        style: TextStyle(
                          color: statusInfo['color'] as Color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (doc.expiryDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: const Color(0xFF64748B).withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expire le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(doc.expiryDate!))}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doc.notes!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'expired':
        return {
          'color': const Color(0xFFEF4444),
          'bgColor': const Color(0xFFFFEDED),
          'label': 'Expiré',
        };
      case 'expiring_soon':
        return {
          'color': const Color(0xFFF59E0B),
          'bgColor': const Color(0xFFFEF3C7),
          'label': 'Expire bientôt',
        };
      case 'valid':
        return {
          'color': const Color(0xFF10B981),
          'bgColor': const Color(0xFFD1FAE5),
          'label': 'Valide',
        };
      case 'permanent':
        return {
          'color': const Color(0xFF1B4FD8),
          'bgColor': const Color(0xFFDEEDFF),
          'label': 'Permanent',
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bgColor': const Color(0xFFF1F5F9),
          'label': 'Non spécifié',
        };
    }
  }
}

// ============================================================================
// TRANSPORTS TAB
// ============================================================================

// ============================================================================
// TRANSPORTS TAB
// ============================================================================
class _TransportsTab extends ConsumerWidget {
  final int truckId;

  const _TransportsTab({required this.truckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportsAsync = ref.watch(truckTransportsProvider(truckId));

    return transportsAsync.when(
      data: (transports) => _buildTransportsContent(context, transports),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B4FD8))),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFEDED),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportsContent(BuildContext context, List<TransportModel> transports) {
    if (transports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0E7FF),
              ),
              child: const Icon(
                Icons.map_rounded,
                size: 56,
                color: Color(0xFF1B4FD8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun transport',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aucun transport enregistré pour ce camion',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Calcul des stats
    final totalVoyages = transports.length;
    final totalRevenus = transports.fold<double>(0, (sum, t) => sum + (t.montantTransport ?? 0));
    final voyagesPayes = transports.where((t) => t.statutPaiement == 'paye').length;
    final voyagesNonPayes = transports.where((t) => t.statutPaiement == 'non_paye').length;
    
    // Calcul durée moyenne
    double? dureeoyenneMins;
    final voyagesAvecDuree = transports.where((t) => 
      t.actualDeparture != null && t.actualArrival != null
    ).toList();
    if (voyagesAvecDuree.isNotEmpty) {
      double totalMins = 0;
      for (final t in voyagesAvecDuree) {
        try {
          final dep = DateTime.parse(t.actualDeparture!);
          final arr = DateTime.parse(t.actualArrival!);
          totalMins += arr.difference(dep).inMinutes;
        } catch (_) {}
      }
      dureeoyenneMins = totalMins / voyagesAvecDuree.length;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ── Résumé des stats ──────────────────────────────────────────────
        _buildStatsCard(totalVoyages, totalRevenus, voyagesPayes, voyagesNonPayes, dureeoyenneMins),
        const SizedBox(height: 24),

        // ── Liste des transports ──────────────────────────────────────────
        ...List.generate(transports.length, (index) {
          final transport = transports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildTransportCard(transport),
          );
        }),
      ],
    );
  }

  Widget _buildStatsCard(int totalVoyages, double totalRevenus, int voyagesPayes, int voyagesNonPayes, double? dureeoyenneMins) {
    final dureeMoyenneStr = dureeoyenneMins != null
        ? '${(dureeoyenneMins ~/ 60).toString().padLeft(2, '0')}h${(dureeoyenneMins % 60).toStringAsFixed(0).padLeft(2, '0')}'
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé des voyages',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          // Grid de stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildStatItem('Total voyages', totalVoyages.toString(), const Color(0xFF1B4FD8), Icons.local_shipping_rounded),
              _buildStatItem(
                'Total revenus',
                '${totalRevenus.toStringAsFixed(2)} FCFA',
                const Color(0xFF10B981),
                Icons.attach_money_rounded,
              ),
              _buildStatItem('Payés', '$voyagesPayes', const Color(0xFF16A34A), Icons.check_circle_rounded),
              _buildStatItem('Non payés', '$voyagesNonPayes', const Color(0xFFDC2626), Icons.pending_rounded),
              if (dureeoyenneMins != null) ...[
                _buildStatItem('Durée moyenne', dureeMoyenneStr, const Color(0xFFF59E0B), Icons.schedule_rounded),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(TransportModel transport) {
    final paymentStatusInfo = _getPaymentStatusInfo(transport.statutPaiement);
    final transportStatusInfo = _getTransportStatusInfo(transport.status);
    
    // Formater les dates
    String formatDate(String? dateStr) {
      if (dateStr == null) return '—';
      try {
        final dt = DateTime.parse(dateStr);
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} à ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return dateStr;
      }
    }

    // Calculer la durée du voyage
    String? calculDuree() {
      if (transport.actualDeparture == null || transport.actualArrival == null) {
        return null;
      }
      try {
        final dep = DateTime.parse(transport.actualDeparture!);
        final arr = DateTime.parse(transport.actualArrival!);
        final mins = arr.difference(dep).inMinutes;
        final hours = mins ~/ 60;
        final mins_rest = mins % 60;
        return '${hours}h${mins_rest.toString().padLeft(2, '0')}';
      } catch (_) {
        return null;
      }
    }

    final duree = calculDuree();
    final departStr = formatDate(transport.actualDeparture ?? transport.scheduledDeparture);
    final arriveeStr = formatDate(transport.actualArrival);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entête : Référence + Itinéraire
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transport.reference,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Itinéraire avec icônes
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              transport.origin,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                          Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              transport.destination,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),

            // Dates et durée
            Row(
              children: [
                Icon(Icons.flight_takeoff_rounded, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    departStr,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.flight_land_rounded, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    arriveeStr,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (duree != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      duree,
                      style: const TextStyle(
                        color: Color(0xFFA16207),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),

            // Montant + Statut paiement + Client (si disponible)
            Row(
              children: [
                Icon(Icons.attach_money_rounded, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${transport.montantTransport?.toStringAsFixed(2) ?? '0.00'} FCFA',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: paymentStatusInfo['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (paymentStatusInfo['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    paymentStatusInfo['label'] as String,
                    style: TextStyle(
                      color: paymentStatusInfo['color'] as Color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Statut du transport
            Row(
              children: [
                Icon(Icons.info_rounded, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Statut : ',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transportStatusInfo['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (transportStatusInfo['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    transportStatusInfo['label'] as String,
                    style: TextStyle(
                      color: transportStatusInfo['color'] as Color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            // Client (si disponible)
            if (transport.clientName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business_rounded, size: 14, color: const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Client : ${transport.clientName}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPaymentStatusInfo(String? status) {
    switch (status) {
      case 'paye':
        return {
          'color': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'label': 'Payé',
        };
      case 'partiel':
        return {
          'color': const Color(0xFFF59E0B),
          'bgColor': const Color(0xFFFEF3C7),
          'label': 'Partiel',
        };
      case 'non_paye':
        return {
          'color': const Color(0xFFDC2626),
          'bgColor': const Color(0xFFFFEDED),
          'label': 'Non payé',
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bgColor': const Color(0xFFF1F5F9),
          'label': 'Non spécifié',
        };
    }
  }

  Map<String, dynamic> _getTransportStatusInfo(String status) {
    switch (status) {
      case 'completed':
        return {
          'color': const Color(0xFF10B981),
          'bgColor': const Color(0xFFD1FAE5),
          'label': 'Complété',
        };
      case 'in_progress':
        return {
          'color': const Color(0xFF1B4FD8),
          'bgColor': const Color(0xFFDEEDFF),
          'label': 'En cours',
        };
      case 'pending':
        return {
          'color': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFDEEDFF),
          'label': 'En attente',
        };
      case 'cancelled':
        return {
          'color': const Color(0xFFEF4444),
          'bgColor': const Color(0xFFFFEDED),
          'label': 'Annulé',
        };
      case 'delayed':
        return {
          'color': const Color(0xFFEA8F1D),
          'bgColor': const Color(0xFFFEF3C7),
          'label': 'Retardé',
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bgColor': const Color(0xFFF1F5F9),
          'label': 'Non spécifié',
        };
    }
  }
}
