import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/driver_model.dart';
import '../../../core/network/api_client.dart';

final driversProvider = AsyncNotifierProviderFamily<DriversNotifier, List<DriverModel>, String>(
  DriversNotifier.new,
);

class DriversNotifier extends FamilyAsyncNotifier<List<DriverModel>, String> {
  @override
  Future<List<DriverModel>> build(String search) async {
    final api      = ref.read(apiClientProvider);
    final response = await api.get('/drivers', params: {
      if (search.isNotEmpty) 'search': search,
      'per_page': 50,
    });
    final data = response.data['data'] as List;
    return data.map((e) => DriverModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createDriver(Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/drivers', data: data);
    ref.invalidateSelf();
  }

  Future<void> updateDriver(int id, Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.put('/drivers/$id', data: data);
    ref.invalidateSelf();
  }

  Future<void> deleteDriver(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/drivers/$id');
    state = AsyncData(state.value?.where((d) => d.id != id).toList() ?? []);
  }
}
