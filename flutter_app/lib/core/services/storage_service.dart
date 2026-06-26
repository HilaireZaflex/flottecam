import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage unifié :
/// - Sur Web   → SharedPreferences (localStorage du browser)
/// - Sur Mobile → FlutterSecureStorage (Keychain iOS / Keystore Android)
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  // Mobile : stockage sécurisé natif
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── WRITE ─────────────────────────────────────────────────────────────────

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return _secureStorage.read(key: key);
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  // ── DELETE ALL ────────────────────────────────────────────────────────────

  Future<void> deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ── CONTAINS ──────────────────────────────────────────────────────────────

  Future<bool> containsKey({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } else {
      return _secureStorage.containsKey(key: key);
    }
  }
}
