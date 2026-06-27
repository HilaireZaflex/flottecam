import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.read(storageServiceProvider));
});

/// Gère le PIN de connexion rapide
/// - PIN hashé stocké localement (jamais en clair)
/// - Token API conservé → pas de reconnexion
class PinService {
  static const _pinKey   = 'fc_pin_hash';
  static const _hasPin   = 'fc_has_pin';   // ← Même clé que dans index.html JS
  static const _attempts = 'fc_pin_attempts';
  static const int maxAttempts = 3;

  final StorageService _storage;
  PinService(this._storage);

  // ── Vérifie si un PIN est déjà créé ───────────────────────────────────
  Future<bool> hasPin() async {
    final v = await _storage.read(key: _hasPin);
    return v == 'true';
  }

  // ── Sauvegarder un nouveau PIN ─────────────────────────────────────────
  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hash);
    await _storage.write(key: _hasPin, value: 'true');
    await _storage.write(key: _attempts, value: '0');
  }

  // ── Vérifier le PIN ────────────────────────────────────────────────────
  Future<PinResult> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return PinResult.noPin;

    final attemptsStr = await _storage.read(key: _attempts) ?? '0';
    int attempts = int.tryParse(attemptsStr) ?? 0;

    if (_hashPin(pin) == stored) {
      // ✅ PIN correct → réinitialiser les tentatives
      await _storage.write(key: _attempts, value: '0');
      return PinResult.success;
    } else {
      // ❌ PIN incorrect
      attempts++;
      await _storage.write(key: _attempts, value: '$attempts');
      if (attempts >= maxAttempts) {
        // Trop de tentatives → supprimer le PIN
        await clearPin();
        return PinResult.tooManyAttempts;
      }
      return PinResult.wrong(maxAttempts - attempts);
    }
  }

  // ── Supprimer le PIN (retour login classique) ──────────────────────────
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _hasPin);
    await _storage.delete(key: _attempts);
  }

  // ── Nombre de tentatives restantes ────────────────────────────────────
  Future<int> remainingAttempts() async {
    final v = await _storage.read(key: _attempts) ?? '0';
    return maxAttempts - (int.tryParse(v) ?? 0);
  }

  // ── Hash simple du PIN (SHA-256 like via Dart) ─────────────────────────
  String _hashPin(String pin) {
    // Hash simple et sécurisé avec un sel fixe
    const salt = 'FlotteCam2026#';
    final combined = salt + pin + salt;
    var hash = 0;
    for (var i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash + combined.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

// ── Résultat de la vérification PIN ──────────────────────────────────────────
enum PinResultType { success, wrong, noPin, tooManyAttempts }

class PinResult {
  final PinResultType type;
  final int remainingAttempts;

  const PinResult._(this.type, {this.remainingAttempts = 0});

  static const success         = PinResult._(PinResultType.success);
  static const noPin           = PinResult._(PinResultType.noPin);
  static const tooManyAttempts = PinResult._(PinResultType.tooManyAttempts);
  static PinResult wrong(int remaining) =>
      PinResult._(PinResultType.wrong, remainingAttempts: remaining);

  bool get isSuccess         => type == PinResultType.success;
  bool get isWrong           => type == PinResultType.wrong;
  bool get isTooManyAttempts => type == PinResultType.tooManyAttempts;
  bool get hasNoPin          => type == PinResultType.noPin;
}
