import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'driver_tracking_screen.dart';
import '../../services/gps_offline_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';

// ── Provider positions ────────────────────────────────────────────────────────
final truckPositionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res  = await api.get('/gps/latest');
  final data = res.data;
  if (data is Map && data['trucks'] != null) {
    return List<Map<String, dynamic>>.from(data['trucks']);
  }
  return [];
});

// ── Écran principal ───────────────────────────────────────────────────────────
class GpsMapScreen extends ConsumerStatefulWidget {
  const GpsMapScreen({super.key});
  @override
  ConsumerState<GpsMapScreen> createState() => _GpsMapScreenState();
}

class _GpsMapScreenState extends ConsumerState<GpsMapScreen> {
  int? _expandedIndex;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(truckPositionsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(truckPositionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
        ),
        actions: [
          // Indicateur offline/online
          Consumer(builder: (context, ref, _) {
            final gpsState = ref.watch(gpsOfflineServiceProvider);
            return Container(
              margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: gpsState.isOnline
                    ? const Color(0xFF10B981).withOpacity(0.15)
                    : const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: gpsState.isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  gpsState.isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: gpsState.isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 10, fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            );
          }),
          GestureDetector(
            onTap: () => ref.invalidate(truckPositionsProvider),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: trucksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4FF4F)),
        ),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text('Erreur: $e', style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.invalidate(truckPositionsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
        data: (trucks) {
          if (trucks.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFD4FF4F), size: 48),
                ),
                const SizedBox(height: 16),
                const Text('Aucun camion GPS actif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Activez le GPS dans l\'app chauffeur', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: trucks.length,
            itemBuilder: (context, i) {
              final truck = trucks[i];
              final isExpanded = _expandedIndex == i;
              return _TruckTrackingCard(
                truck: truck,
                isExpanded: isExpanded,
                onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Card camion avec carte expandable ─────────────────────────────────────────
class _TruckTrackingCard extends StatelessWidget {
  final Map<String, dynamic> truck;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TruckTrackingCard({
    required this.truck,
    required this.isExpanded,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'on_mission':     return const Color(0xFFD4FF4F); // vert citron
      case 'available':      return const Color(0xFF34D399);  // vert
      case 'maintenance':    return const Color(0xFFFBBF24);  // orange
      case 'out_of_service': return const Color(0xFFEF4444);  // rouge
      default:               return Colors.white38;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'on_mission':     return 'En mission';
      case 'available':      return 'Disponible';
      case 'maintenance':    return 'Maintenance';
      case 'out_of_service': return 'Hors service';
      default:               return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status      = truck['status'] as String? ?? 'available';
    final loc         = truck['location'] as Map<String, dynamic>?;
    final hasGps      = loc != null;
    final color       = _statusColor(status);
    final plateNumber = truck['plate_number'] as String? ?? 'N/A';
    final brand       = truck['brand'] as String? ?? '';
    final model       = truck['model'] as String? ?? '';
    final driverName  = truck['driver_name'] as String?;
    final speed       = hasGps ? (loc!['speed'] ?? 0.0) : 0.0;
    final address     = hasGps ? (loc!['address'] as String? ?? '') : '';

    // Lat/Lng
    final lat = hasGps ? double.tryParse('${loc!['latitude']}')  ?? 12.3472 : 12.3472;
    final lng = hasGps ? double.tryParse('${loc!['longitude']}') ?? -6.8897 : -6.8897;

    return GestureDetector(
      onTap: hasGps ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: isExpanded
              ? Border.all(color: color.withOpacity(0.5), width: 1.5)
              : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            // ── Header card ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Mini carte ou icône
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: hasGps
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.flottecam.app',
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(lat, lng),
                                  width: 20,
                                  height: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        )
                      : Icon(Icons.location_off_rounded, color: Colors.white24, size: 28),
                ),
                const SizedBox(width: 14),
                // Infos camion
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          '$brand $model',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      plateNumber,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    if (driverName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '👤 $driverName',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Stats row
                    Row(children: [
                      _StatChip(label: 'Vitesse', value: '${speed.toString().split('.')[0]} km/h'),
                      const SizedBox(width: 10),
                      _StatChip(label: 'Statut', value: _statusLabel(status), color: color),
                    ]),
                  ]),
                ),
                // Actions: chevron + tracking btn
                Column(mainAxisSize: MainAxisSize.min, children: [
                  if (hasGps)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? color : Colors.white38,
                        size: 24,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Bouton tracking chauffeur
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverTrackingScreen(
                          truckId: truck['id'] as int,
                          plateNumber: plateNumber,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.navigation_rounded, color: color, size: 12),
                        const SizedBox(width: 4),
                        Text('GPS', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
              ]),
            ),

            // ── Carte expandable ─────────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: isExpanded && hasGps
                  ? Column(children: [
                      Divider(color: Colors.white.withOpacity(0.06), height: 1),
                      // Grande carte
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: SizedBox(
                          height: 280,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.flottecam.app',
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(lat, lng),
                                  width: 50,
                                  height: 50,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(color: color.withOpacity(0.4), blurRadius: 8),
                                          ],
                                        ),
                                        child: Text(
                                          plateNumber,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 12, height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      // Adresse
                      if (address.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            Icon(Icons.location_on_rounded, color: color, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                address,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ),
                    ])
                  : const SizedBox(height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip stat ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500)),
      const SizedBox(height: 1),
      Text(
        value,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ]);
  }
}
