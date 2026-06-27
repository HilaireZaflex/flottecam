import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service de mise à jour — la vérification est faite en JS dans index.html
/// Ce service ne fait rien car le rechargement est géré avant Flutter
class UpdateService {
  static Future<void> checkAndUpdate() async {
    // Vérification gérée par JavaScript dans index.html (avant Flutter)
    // Plus fiable et sans conflit avec le cycle de vie Flutter
    return;
  }
}
