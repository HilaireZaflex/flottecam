import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../auth/auth_provider.dart';

final myTripsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  // driver_id injecté par _enrichUser dans auth_provider
  final driverId = user['driver_id'];
  if (driverId == null) return [];
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get('/drivers/$driverId/transports', params: {'per_page': '50'});
    final data = res.data;
    final List items = (data is Map ? (data['data'] ?? []) : (data ?? []));
    return items.cast<Map<String, dynamic>>();
  } catch (e) {
    return [];
  }
});

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Mes Voyages')),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (trips) {
          if (trips.isEmpty) return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.route_rounded, size: 64, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('Aucun voyage pour l\'instant',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
            ]),
          );
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myTripsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (ctx, i) => _TripCard(trip: trips[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripCard({required this.trip});

  String _fmt(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM à HH:mm').format(dt);
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final origin      = trip['origin']      as String? ?? '—';
    final destination = trip['destination'] as String? ?? '—';
    final status      = trip['status']      as String? ?? '';
    final departure   = _fmt(trip['actual_departure'] as String? ?? trip['scheduled_departure'] as String?);
    final arrival     = trip['actual_arrival'] as String?;
    final montantRaw  = trip['montant_transport'];
    final montant     = montantRaw == null ? 0 : (montantRaw is num ? montantRaw.toInt() : int.tryParse(montantRaw.toString()) ?? 0);
    final paiement    = trip['statut_paiement'] as String? ?? 'non_paye';
    final reference   = trip['reference'] as String? ?? '';

    final (Color statusColor, String statusLabel) = switch (status) {
      'completed'   => (const Color(0xFF16A34A), 'Terminé'),
      'in_progress' => (const Color(0xFFEA580C), 'En cours'),
      'pending'     => (const Color(0xFF2563EB), 'Planifié'),
      'cancelled'   => (const Color(0xFF94A3B8), 'Annulé'),
      _             => (const Color(0xFF94A3B8), status),
    };

    final (Color payColor, String payLabel) = switch (paiement) {
      'paye'    => (const Color(0xFF16A34A), 'Payé'),
      'partiel' => (const Color(0xFFEA580C), 'Partiel'),
      _         => (const Color(0xFFDC2626), 'Non payé'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(statusLabel, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
            const Spacer(),
            if (reference.isNotEmpty)
              Text(reference, style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Itinéraire
            Row(children: [
              const Icon(Icons.trip_origin, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(child: Text(origin,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(width: 2, height: 16, color: const Color(0xFFE2E8F0)),
            ),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF1B4FD8)),
              const SizedBox(width: 8),
              Expanded(child: Text(destination,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B4FD8)))),
            ]),
            const SizedBox(height: 12),
            // Dates
            Row(children: [
              const Icon(Icons.flight_takeoff_rounded, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('Départ : $departure', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ]),
            if (arrival != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.flight_land_rounded, size: 13, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text('Arrivée : ${_fmt(arrival)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
              ]),
            ],
            if (montant > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                Text(NumberFormat('#,###').format(montant) + ' FCFA',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: payColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(payLabel, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: payColor)),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}
