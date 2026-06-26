import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/gps_offline_service.dart';

/// Écran pour le CHAUFFEUR — activation du tracking GPS
/// Avec mode offline automatique
class DriverTrackingScreen extends ConsumerStatefulWidget {
  final int truckId;
  final String plateNumber;

  const DriverTrackingScreen({
    super.key,
    required this.truckId,
    required this.plateNumber,
  });

  @override
  ConsumerState<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends ConsumerState<DriverTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final gpsState  = ref.watch(gpsOfflineServiceProvider);
    final gpsService = ref.read(gpsOfflineServiceProvider.notifier);

    final position = gpsState.currentPosition;
    final lat = position?.latitude  ?? 12.3472;
    final lng = position?.longitude ?? -6.8897;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mon Tracking GPS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(widget.plateNumber,
              style: const TextStyle(color: Color(0xFFD4FF4F), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
        ),
      ),
      body: Column(children: [
        // ── Barre statut réseau ──────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: gpsState.isOnline
              ? const Color(0xFF10B981).withOpacity(0.15)
              : const Color(0xFFF59E0B).withOpacity(0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: gpsState.isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                gpsState.isOnline ? '🌐 En ligne — données envoyées en temps réel' : '📵 Hors ligne — données stockées localement',
                style: TextStyle(
                  color: gpsState.isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!gpsState.isOnline && gpsState.pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${gpsState.pendingCount} en attente',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
          ]),
        ),

        // ── Carte ────────────────────────────────────────────────────────────
        Expanded(
          flex: 3,
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
              if (position != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4FF4F),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: const Color(0xFFD4FF4F).withOpacity(0.5), blurRadius: 10)],
                        ),
                        child: Text(
                          widget.plateNumber,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 9),
                        ),
                      ),
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4FF4F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: const Color(0xFFD4FF4F).withOpacity(0.5), blurRadius: 8)],
                        ),
                      ),
                    ]),
                  ),
                ]),
            ],
          ),
        ),

        // ── Panneau de contrôle ──────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // Statut message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    gpsState.statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(children: [
              Expanded(child: _StatBox(
                icon: Icons.cloud_upload_rounded,
                label: 'Points envoyés',
                value: '${gpsState.syncedCount}',
                color: const Color(0xFF10B981),
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(
                icon: Icons.pending_rounded,
                label: 'En attente',
                value: '${gpsState.pendingCount}',
                color: const Color(0xFFF59E0B),
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(
                icon: Icons.speed_rounded,
                label: 'Vitesse',
                value: position != null
                    ? '${(position.speed * 3.6).clamp(0, 200).toStringAsFixed(0)} km/h'
                    : '— km/h',
                color: const Color(0xFFD4FF4F),
              )),
            ]),
            const SizedBox(height: 16),

            // Boutons
            if (!gpsState.isTracking) ...[
              // Bouton démarrer
              GestureDetector(
                onTap: () => gpsService.startTracking(widget.truckId),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4FF4F), Color(0xFFAAE800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4FF4F).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                    SizedBox(width: 8),
                    Text('Démarrer le tracking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
              ),
            ] else ...[
              // Bouton forcer sync
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => gpsService.forcSync(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('Synchroniser', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Bouton arrêter
                Expanded(
                  child: GestureDetector(
                    onTap: () => gpsService.stopTracking(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.stop_rounded, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 8),
                        Text('Arrêter', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ],

            // Info offline
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: const Row(children: [
                Icon(Icons.offline_bolt_rounded, color: AppTheme.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode hors-ligne actif — vos positions sont enregistrées même sans internet et synchronisées automatiquement au retour du réseau.',
                    style: TextStyle(color: AppTheme.primary, fontSize: 11, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]),
  );
}
