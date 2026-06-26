import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/truck_model.dart';
import '../../../core/network/api_client.dart';

final trucksProvider = AsyncNotifierProviderFamily<TrucksNotifier, List<TruckModel>, String>(
  TrucksNotifier.new,
);

class TrucksNotifier extends FamilyAsyncNotifier<List<TruckModel>, String> {
  @override
  Future<List<TruckModel>> build(String search) async {
    final api      = ref.read(apiClientProvider);
    final response = await api.get('/trucks', params: {
      if (search.isNotEmpty) 'search': search,
      'per_page': 50,
    });
    final data = response.data['data'] as List;
    return data.map((e) => TruckModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(int id, String status) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/trucks/$id/status', data: {'status': status});
    ref.invalidateSelf();
  }

  Future<void> deleteTruck(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/trucks/$id');
    state = AsyncData(state.value?.where((t) => t.id != id).toList() ?? []);
  }

  Future<void> createTruck(Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/trucks', data: data);
    ref.invalidateSelf();
  }

  Future<void> updateTruck(int id, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.put('/trucks/$id', data: data);
    ref.invalidateSelf();
  }
}
