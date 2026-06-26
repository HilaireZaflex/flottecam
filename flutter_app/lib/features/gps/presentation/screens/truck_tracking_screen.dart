import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as Math;
import '../../providers/gps_provider.dart';
import '../../../../core/theme/app_theme.dart';

class TruckTrackingScreen extends ConsumerStatefulWidget {
  final int truckId;
  final String plateNumber;

  const TruckTrackingScreen({
    super.key,
    required this.truckId,
    required this.plateNumber,
  });

  @override
  ConsumerState<TruckTrackingScreen> createState() => _TruckTrackingScreenState();
}

class _TruckTrackingScreenState extends ConsumerState<TruckTrackingScreen> {
  late MapController _mapController;
  String _selectedTimeRange = '24h';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - 
        Math.cos((p2.latitude - p1.latitude) * p) / 2 +
        Math.cos(p1.latitude * p) * 
        Math.cos(p2.latitude * p) * 
        (1 - Math.cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    final trackingHistoryAsync = ref.watch(
      truckTrackingHistoryProvider(
        (truckId: widget.truckId, timeRange: _selectedTimeRange),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Trace - ${widget.plateNumber}'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: trackingHistoryAsync.when(
        data: (positions) {
          if (positions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 48,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune donnée GPS disponible',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }

          // Parse positions
          final points = positions
              .where((p) {
                try {
                  double.parse(p['latitude'].toString());
                  double.parse(p['longitude'].toString());
                  return true;
                } catch (e) {
                  return false;
                }
              })
              .map((p) => LatLng(
                    double.parse(p['latitude'].toString()),
                    double.parse(p['longitude'].toString()),
                  ))
              .toList();

          if (points.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 48,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Données GPS invalides',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }

          // Calculate stats
          double totalDistance = 0;
          for (int i = 0; i < points.length - 1; i++) {
            totalDistance += _calculateDistance(points[i], points[i + 1]);
          }

          final duration = positions.length > 1
              ? DateTime.parse(positions.last['timestamp'].toString())
                  .difference(
                      DateTime.parse(positions.first['timestamp'].toString()))
              : const Duration();

          final avgSpeed = duration.inHours > 0
              ? (totalDistance / duration.inHours).toStringAsFixed(1)
              : '0';

          // Build markers
          final markers = <Marker>[
            // Start marker (green)
            Marker(
              point: points.first,
              width: 40,
              height: 40,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // End marker (red)
            Marker(
              point: points.last,
              width: 40,
              height: 40,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEF4444),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Intermediate points
            ...points.skip(1).take(points.length - 2).map((point) {
              final index = points.indexOf(point);
              return Marker(
                point: point,
                width: 10,
                height: 10,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  width: 6,
                  height: 6,
                ),
              );
            }).toList(),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: points.isNotEmpty ? points.first : const LatLng(0, 0),
                  initialZoom: 13,
                  minZoom: 2,
                  maxZoom: 18,
                  onMapReady: () {
                    if (points.length > 1) {
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(points),
                          padding: const EdgeInsets.all(100),
                        ),
                      );
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.fleet_saas',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 3,
                        color: AppTheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Stats panel
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.95),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Distance totale',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '${totalDistance.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Durée',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '${duration.inHours}h ${(duration.inMinutes % 60)}m',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Vitesse moy.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '$avgSpeed km/h',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Time filter buttons
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimeButton('6h'),
                      const SizedBox(width: 8),
                      _buildTimeButton('12h'),
                      const SizedBox(width: 8),
                      _buildTimeButton('24h'),
                      const SizedBox(width: 8),
                      _buildTimeButton('48h'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur: $error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(String label) {
    final isSelected = _selectedTimeRange == label;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedTimeRange = label);
        ref.refresh(
          truckTrackingHistoryProvider(
            (truckId: widget.truckId, timeRange: label),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primary : const Color(0xFF1E293B),
        foregroundColor: isSelected ? Colors.white : const Color(0xFF94A3B8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: isSelected
            ? BorderSide.none
            : const BorderSide(color: Color(0xFF475569), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
