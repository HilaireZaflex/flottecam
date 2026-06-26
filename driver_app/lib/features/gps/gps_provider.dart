import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/api_client.dart';

class GpsState {
  final bool isTracking;
  final Position? position;
  final String status; // 'idle' | 'tracking' | 'error'
  final int sentCount;
  final DateTime? lastSent;
  final String? error;

  const GpsState({
    this.isTracking = false,
    this.position,
    this.status = 'idle',
    this.sentCount = 0,
    this.lastSent,
    this.error,
  });

  GpsState copyWith({
    bool? isTracking, Position? position, String? status,
    int? sentCount, DateTime? lastSent, String? error,
  }) => GpsState(
    isTracking: isTracking ?? this.isTracking,
    position: position ?? this.position,
    status: status ?? this.status,
    sentCount: sentCount ?? this.sentCount,
    lastSent: lastSent ?? this.lastSent,
    error: error,
  );
}

final gpsProvider = StateNotifierProvider<GpsNotifier, GpsState>((ref) {
  return GpsNotifier(ref.read(apiClientProvider));
});

class GpsNotifier extends StateNotifier<GpsState> {
  final ApiClient _api;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  GpsNotifier(this._api) : super(const GpsState());

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(status: 'error', error: 'GPS désactivé sur cet appareil');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(status: 'error', error: 'Permission GPS refusée');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(status: 'error', error: 'Permission GPS refusée définitivement');
      return false;
    }
    return true;
  }

  Future<void> startTracking({required int truckId, required int driverId}) async {
    if (!await _checkPermission()) return;

    state = state.copyWith(isTracking: true, status: 'tracking', error: null);

    // Écouter les positions en temps réel
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    ).listen((position) async {
      state = state.copyWith(position: position);
      await _sendPosition(position, truckId: truckId, driverId: driverId);
    });
  }

  Future<void> _sendPosition(Position pos, {required int truckId, required int driverId}) async {
    try {
      await _api.post('/gps/update', data: {
        'truck_id':   truckId,
        'driver_id':  driverId,
        'latitude':   pos.latitude,
        'longitude':  pos.longitude,
        'speed':      (pos.speed * 3.6).clamp(0, 300), // m/s → km/h
        'heading':    pos.heading,
        'accuracy':   pos.accuracy,
        'altitude':   pos.altitude,
        'status':     pos.speed > 1 ? 'moving' : 'idle',
        'recorded_at': DateTime.now().toIso8601String(),
      });
      state = state.copyWith(
        sentCount: state.sentCount + 1,
        lastSent: DateTime.now(),
      );
    } catch (_) {}
  }

  void stopTracking() {
    _timer?.cancel();
    _positionStream?.cancel();
    state = state.copyWith(isTracking: false, status: 'idle');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
