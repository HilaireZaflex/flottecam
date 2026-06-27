import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../data/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authStateProvider).value);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  // Utilise le StorageService unifié (web + mobile)
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<UserModel?> build() async {
    final token    = await _storage.read(key: AppConstants.tokenKey);
    final userJson = await _storage.read(key: AppConstants.userKey);

    if (token != null && userJson != null) {
      try {
        // Charger l'utilisateur depuis le cache local immédiatement
        final user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

        // Vérifier le token en arrière-plan (sans bloquer l'UI)
        _verifyTokenInBackground(token);

        return user;
      } catch (_) {
        await _storage.delete(key: AppConstants.tokenKey);
        await _storage.delete(key: AppConstants.userKey);
      }
    }
    return null;
  }

  /// Vérifie le token en arrière-plan sans bloquer le démarrage
  Future<void> _verifyTokenInBackground(String token) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/auth/me');
      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      // Mettre à jour l'état silencieusement
      state = AsyncData(user);
    } catch (e) {
      // Token expiré → déconnecter proprement
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: AppConstants.userKey);
      state = const AsyncData(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api      = ref.read(apiClientProvider);
      final response = await api.post('/auth/login', data: {'email': email, 'password': password});
      return _saveAndReturn(response.data);
    });
  }

  Future<void> register({
    required String companyName,
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api      = ref.read(apiClientProvider);
      final response = await api.post('/auth/register', data: {
        'company_name': companyName, 'name': name, 'email': email,
        'password': password, 'password_confirmation': confirm,
      });
      return _saveAndReturn(response.data);
    });
  }

  Future<void> logout() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/auth/logout');
    } catch (_) {}
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    state = const AsyncData(null);
  }

  Future<UserModel> _saveAndReturn(Map<String, dynamic> data) async {
    final user  = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.userKey,  value: jsonEncode(user.toJson()));
    return user;
  }
}
