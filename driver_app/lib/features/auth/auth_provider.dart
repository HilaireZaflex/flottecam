import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';

final _storage = const FlutterSecureStorage();

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ApiClient _api;
  AuthNotifier(this._api) : super(const AsyncValue.loading()) {
    _init();
  }

  // Enrichit le user avec driver_id et current_truck_id depuis la relation driver
  Map<String, dynamic> _enrichUser(Map<String, dynamic> user) {
    try {
      final raw = user['driver'];
      if (raw == null) return user;
      final driver = Map<String, dynamic>.from(raw as Map);
      user['driver_id']        = driver['id'];
      user['current_truck_id'] = driver['current_truck_id'];
      user['first_name']       = driver['first_name'];
      user['last_name']        = driver['last_name'];
      user['phone']            = driver['phone'];
    } catch (_) {}
    return user;
  }

  Future<void> _init() async {
    final token = await _storage.read(key: 'driver_token');
    if (token != null) {
      try {
        final res = await _api.get('/auth/me');
        final user = _enrichUser(res.data['user'] as Map<String, dynamic>);
        state = AsyncValue.data(user);
      } catch (_) {
        await _storage.delete(key: 'driver_token');
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'] as String;
      final user  = _enrichUser(res.data['user'] as Map<String, dynamic>);
      await _storage.write(key: 'driver_token', value: token);
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'driver_token');
    state = const AsyncValue.data(null);
  }
}
