import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../gps_provider.dart';
import '../../auth/auth_provider.dart';

class GpsScreen extends ConsumerWidget {
  const GpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gps  = ref.watch(gpsProvider);
    final user = ref.watch(authProvider).value;
    final truckId  = (user?['current_truck_id'] as int?) ?? 0;
    final driverId = (user?['driver_id'] as int?) ?? (user?['id'] as int?) ?? 0;

    final hasPosition = gps.position != null;
    final lat = gps.position?.latitude  ?? 12.65;
    final lng = gps.position?.longitude ?? -8.00;
    final speed = ((gps.position?.speed ?? 0) * 3.6).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Suivi GPS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gps.isTracking ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: gps.isTracking ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    )),
                  const SizedBox(width: 6),
                  Text(gps.isTracking ? 'Actif' : 'Arrêté',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: gps.isTracking ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    )),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Carte ──────────────────────────────────────────────────────
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: hasPosition ? 15 : 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flottecam.driver',
              ),
              if (hasPosition)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 50, height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4FD8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ]),
            ],
          ),
        ),

        // ── Panel infos ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: Column(children: [
            // Stats en ligne
            Row(children: [
              _StatBox(
                icon: Icons.speed_rounded,
                label: 'Vitesse',
                value: '$speed km/h',
                color: const Color(0xFF1B4FD8),
              ),
              const SizedBox(width: 12),
              _StatBox(
                icon: Icons.my_location_rounded,
                label: 'Précision',
                value: hasPosition ? '${gps.position!.accuracy.toStringAsFixed(0)}m' : '—',
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 12),
              _StatBox(
                icon: Icons.upload_rounded,
                label: 'Envois',
                value: '${gps.sentCount}',
                color: const Color(0xFFEA580C),
              ),
            ]),
            const SizedBox(height: 12),

            // Coordonnées
            if (hasPosition)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF1B4FD8), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                  ),
                  const Spacer(),
                  if (gps.lastSent != null)
                    Text(
                      DateFormat('HH:mm:ss').format(gps.lastSent!),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                ]),
              ),

            // Erreur
            if (gps.error != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(gps.error!, style: const TextStyle(
                    fontSize: 12, color: Color(0xFFDC2626)))),
                ]),
              ),

            const SizedBox(height: 14),

            // Bouton start/stop
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: truckId == 0 ? null : () {
                  if (gps.isTracking) {
                    ref.read(gpsProvider.notifier).stopTracking();
                  } else {
                    ref.read(gpsProvider.notifier).startTracking(
                      truckId: truckId, driverId: driverId);
                  }
                },
                icon: Icon(gps.isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
                label: Text(
                  truckId == 0
                    ? 'Aucun camion assigné'
                    : gps.isTracking
                        ? 'Arrêter le suivi GPS'
                        : 'Démarrer le suivi GPS',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gps.isTracking ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ]),
    ),
  );
}
