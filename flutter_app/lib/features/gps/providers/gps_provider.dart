import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';

/// Provider that fetches all truck positions
final truckPositionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/gps/latest');
    return List<Map<String, dynamic>>.from(response.data['trucks'] ?? []);
  } catch (e) {
    return [];
  }
});

/// Auto-refresh every 30 seconds
final gpsRefreshProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (i) => i);
});

/// Driver's current location
final currentLocationProvider = FutureProvider.autoDispose<Position?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  } catch (e) {
    return null;
  }
});

/// Fetch truck tracking history for a specific truck
final truckTrackingHistoryProvider = FutureProvider.autoDispose.family<
    List<Map<String, dynamic>>,
    ({int truckId, String timeRange})>((ref, params) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get(
      '/gps/history/${params.truckId}',
      params: {'timeRange': params.timeRange},
    );
    return List<Map<String, dynamic>>.from(response.data['positions'] ?? []);
  } catch (e) {
    return [];
  }
});

/// Post GPS update to backend — utilise apiClientProvider via ProviderContainer
Future<void> postGpsUpdate({
  required WidgetRef ref,
  required int truckId,
  required double latitude,
  required double longitude,
  required double speed,
  required double heading,
  required double accuracy,
}) async {
  final api = ref.read(apiClientProvider);
  try {
    await api.post(
      '/gps/update',
      data: {
        'truck_id': truckId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
      },
    );
  } catch (e) {
    // Silently fail - don't disrupt user experience
  }
}

/// Vérifie et demande la permission GPS (mobile uniquement)
/// Sur web, le browser gère la permission nativement via le prompt
Future<bool> checkAndRequestLocationPermission() async {
  if (kIsWeb) return true; // Le browser gère lui-même

  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  } catch (e) {
    return false;
  }
}
