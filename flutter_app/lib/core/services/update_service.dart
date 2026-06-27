import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Service de mise à jour automatique pour la PWA
/// Vérifie la version au démarrage et recharge si nécessaire
class UpdateService {
  static const _versionKey = 'flottecam_version';

  /// Vérifie si une nouvelle version est disponible et recharge si oui
  static Future<void> checkAndUpdate() async {
    if (!kIsWeb) return; // Uniquement sur web/PWA

    try {
      // Récupérer la version serveur (no-cache pour toujours avoir la dernière)
      final response = await http.get(
        Uri.parse('/version.json?t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final serverVersion = data['build_number']?.toString() ?? '1';

      // Récupérer la version stockée localement
      final storage = html.window.localStorage;
      final localVersion = storage[_versionKey];

      if (localVersion == null) {
        // Première visite → sauvegarder la version
        storage[_versionKey] = serverVersion;
        return;
      }

      if (localVersion != serverVersion) {
        // Nouvelle version détectée → mettre à jour et recharger
        storage[_versionKey] = serverVersion;
        print('[FlotteCam] Nouvelle version $serverVersion détectée → rechargement');

        // Vider tous les caches du navigateur
        await _clearAllCaches();

        // Recharger la page (force le téléchargement des nouveaux fichiers)
        html.window.location.reload();
      }
    } catch (e) {
      // Silencieux — ne pas bloquer l'app si pas de connexion
      print('[FlotteCam] Vérification mise à jour ignorée: $e');
    }
  }

  /// Vide tous les caches du navigateur
  static Future<void> _clearAllCaches() async {
    try {
      // Vider le Cache API (Service Worker caches)
      final cacheStorage = html.window.caches;
      if (cacheStorage != null) {
        final keys = await cacheStorage.keys();
        for (final key in keys) {
          await cacheStorage.delete(key);
        }
      }
    } catch (e) {
      // Ignorer si Cache API non disponible
    }
  }
}
