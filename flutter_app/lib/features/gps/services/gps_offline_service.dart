import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/network/api_client.dart';

// ── Clés de stockage local ────────────────────────────────────────────────────
const _kPendingKey   = 'gps_pending_locations';
const _kLastSyncKey  = 'gps_last_sync';
const _kTrackingKey  = 'gps_is_tracking';

// ── Modèle de point GPS en attente ────────────────────────────────────────────
class PendingGpsPoint {
  final int    truckId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double accuracy;
  final double altitude;
  final String status;
  final DateTime recordedAt;

  const PendingGpsPoint({
    required this.truckId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.altitude,
    required this.status,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'truck_id':    truckId,
    'latitude':    latitude,
    'longitude':   longitude,
    'speed':       speed,
    'heading':     heading,
    'accuracy':    accuracy,
    'altitude':    altitude,
    'status':      status,
    'recorded_at': recordedAt.toIso8601String(),
  };

  factory PendingGpsPoint.fromJson(Map<String, dynamic> json) => PendingGpsPoint(
    truckId:    json['truck_id'] as int,
    latitude:   (json['latitude'] as num).toDouble(),
    longitude:  (json['longitude'] as num).toDouble(),
    speed:      (json['speed'] as num? ?? 0).toDouble(),
    heading:    (json['heading'] as num? ?? 0).toDouble(),
    accuracy:   (json['accuracy'] as num? ?? 0).toDouble(),
    altitude:   (json['altitude'] as num? ?? 0).toDouble(),
    status:     json['status'] as String? ?? 'moving',
    recordedAt: DateTime.parse(json['recorded_at'] as String),
  );
}

// ── État du service GPS ───────────────────────────────────────────────────────
class GpsServiceState {
  final bool   isTracking;
  final bool   isOnline;
  final int    pendingCount;
  final int    syncedCount;
  final String statusMessage;
  final DateTime? lastSync;
  final Position? currentPosition;

  const GpsServiceState({
    this.isTracking    = false,
    this.isOnline      = true,
    this.pendingCount  = 0,
    this.syncedCount   = 0,
    this.statusMessage = 'Inactif',
    this.lastSync,
    this.currentPosition,
  });

  GpsServiceState copyWith({
    bool?     isTracking,
    bool?     isOnline,
    int?      pendingCount,
    int?      syncedCount,
    String?   statusMessage,
    DateTime? lastSync,
    Position? currentPosition,
  }) => GpsServiceState(
    isTracking:     isTracking     ?? this.isTracking,
    isOnline:       isOnline       ?? this.isOnline,
    pendingCount:   pendingCount   ?? this.pendingCount,
    syncedCount:    syncedCount    ?? this.syncedCount,
    statusMessage:  statusMessage  ?? this.statusMessage,
    lastSync:       lastSync       ?? this.lastSync,
    currentPosition: currentPosition ?? this.currentPosition,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────
final gpsOfflineServiceProvider =
    StateNotifierProvider<GpsOfflineService, GpsServiceState>(
  (ref) => GpsOfflineService(ref),
);

// ── Service principal ─────────────────────────────────────────────────────────
class GpsOfflineService extends StateNotifier<GpsServiceState> {
  final Ref _ref;
  Timer?              _trackingTimer;
  Timer?              _syncTimer;
  StreamSubscription? _connectivitySub;

  GpsOfflineService(this._ref) : super(const GpsServiceState()) {
    _initConnectivity();
    _loadPendingCount();
  }

  // ── Initialisation connectivité ─────────────────────────────────────────────
  void _initConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(isOnline: isOnline);
      if (isOnline && state.pendingCount > 0) {
        _syncPending(); // Sync automatique quand le réseau revient
      }
    });

    // Vérification initiale
    Connectivity().checkConnectivity().then((results) {
      state = state.copyWith(
        isOnline: results.any((r) => r != ConnectivityResult.none),
      );
    });
  }

  // ── Charger le nombre de points en attente ──────────────────────────────────
  Future<void> _loadPendingCount() async {
    final prefs   = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_kPendingKey) ?? [];
    state = state.copyWith(pendingCount: pending.length);
  }

  // ── Démarrer le tracking ────────────────────────────────────────────────────
  Future<void> startTracking(int truckId) async {
    // Vérifier les permissions (sur web, le browser gère le prompt nativement)
    if (!kIsWeb) {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        state = state.copyWith(statusMessage: '⛔ Permission GPS refusée');
        return;
      }
    }

    // Sauvegarder l'état de tracking
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTrackingKey, true);

    state = state.copyWith(
      isTracking:    true,
      statusMessage: '📍 Tracking actif',
    );

    // Timer : envoyer position toutes les 30 secondes
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _captureAndSend(truckId);
    });

    // Premier envoi immédiat
    await _captureAndSend(truckId);

    // Timer de sync toutes les 2 minutes si hors ligne
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (state.isOnline && state.pendingCount > 0) _syncPending();
    });
  }

  // ── Arrêter le tracking ─────────────────────────────────────────────────────
  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _syncTimer?.cancel();
    _trackingTimer = null;
    _syncTimer     = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTrackingKey, false);

    state = state.copyWith(
      isTracking:    false,
      statusMessage: '⏹ Tracking arrêté',
    );
  }

  // ── Capturer la position et envoyer / stocker ───────────────────────────────
  Future<void> _captureAndSend(int truckId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      state = state.copyWith(currentPosition: position);

      final point = PendingGpsPoint(
        truckId:   truckId,
        latitude:  position.latitude,
        longitude: position.longitude,
        speed:     (position.speed * 3.6).clamp(0, 200), // m/s → km/h
        heading:   position.heading,
        accuracy:  position.accuracy,
        altitude:  position.altitude,
        status:    position.speed > 0.5 ? 'moving' : 'stopped',
        recordedAt: DateTime.now(),
      );

      if (state.isOnline) {
        // En ligne : envoyer directement
        final success = await _sendToServer(point);
        if (!success) {
          await _storeLocally(point); // Échec → stocker localement
        } else {
          state = state.copyWith(
            statusMessage: '✅ Position envoyée (${_timeStr()})',
            lastSync: DateTime.now(),
          );
        }
      } else {
        // Hors ligne : stocker localement
        await _storeLocally(point);
        state = state.copyWith(
          statusMessage: '📥 Hors ligne — ${state.pendingCount + 1} point(s) en attente',
        );
      }
    } catch (e) {
      debugPrint('GPS capture error: $e');
      state = state.copyWith(statusMessage: '⚠️ Erreur GPS: $e');
    }
  }

  // ── Envoyer au serveur ──────────────────────────────────────────────────────
  Future<bool> _sendToServer(PendingGpsPoint point) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.post('/gps/update', data: point.toJson());
      return true;
    } catch (e) {
      debugPrint('GPS send error: $e');
      return false;
    }
  }

  // ── Stocker localement ──────────────────────────────────────────────────────
  Future<void> _storeLocally(PendingGpsPoint point) async {
    final prefs   = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_kPendingKey) ?? [];

    // Limiter à 500 points max (éviter débordement mémoire)
    if (pending.length >= 500) pending.removeAt(0);

    pending.add(jsonEncode(point.toJson()));
    await prefs.setStringList(_kPendingKey, pending);

    state = state.copyWith(pendingCount: pending.length);
  }

  // ── Synchroniser les points en attente ─────────────────────────────────────
  Future<void> _syncPending() async {
    final prefs   = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_kPendingKey) ?? [];

    if (pending.isEmpty) return;

    state = state.copyWith(statusMessage: '🔄 Synchronisation de ${pending.length} point(s)...');

    int synced = 0;
    final failed = <String>[];

    for (final item in pending) {
      try {
        final point = PendingGpsPoint.fromJson(jsonDecode(item) as Map<String, dynamic>);
        final success = await _sendToServer(point);
        if (success) {
          synced++;
        } else {
          failed.add(item);
        }
      } catch (e) {
        failed.add(item);
      }
    }

    // Sauvegarder les points qui ont échoué
    await prefs.setStringList(_kPendingKey, failed);
    if (synced > 0) {
      await prefs.setString(_kLastSyncKey, DateTime.now().toIso8601String());
    }

    state = state.copyWith(
      pendingCount:  failed.length,
      syncedCount:   state.syncedCount + synced,
      lastSync:      synced > 0 ? DateTime.now() : state.lastSync,
      statusMessage: synced > 0
          ? '✅ $synced point(s) synchronisé(s) (${_timeStr()})'
          : '⚠️ Synchronisation partielle',
    );
  }

  // ── Forcer la synchronisation ───────────────────────────────────────────────
  Future<void> forcSync() async {
    if (!state.isOnline) {
      state = state.copyWith(statusMessage: '📵 Pas de connexion internet');
      return;
    }
    await _syncPending();
  }

  // ── Helper: heure courante ─────────────────────────────────────────────────
  String _timeStr() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
