import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/transport_model.dart';
import '../../../core/network/api_client.dart';

final transportsProvider = AsyncNotifierProviderFamily<TransportsNotifier, List<TransportModel>, String>(
  TransportsNotifier.new,
);

final transportDetailProvider = FutureProviderFamily<TransportModel, int>((ref, id) async {
  final api      = ref.read(apiClientProvider);
  final response = await api.get('/transports/$id');
  return TransportModel.fromJson(response.data['transport'] as Map<String, dynamic>);
});

class TransportsNotifier extends FamilyAsyncNotifier<List<TransportModel>, String> {
  @override
  Future<List<TransportModel>> build(String search) async {
    final api      = ref.read(apiClientProvider);
    final response = await api.get('/transports', params: {
      if (search.isNotEmpty) 'search': search,
      'per_page': 50,
    });
    final data = response.data['data'] as List;
    return data.map((e) => TransportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createTransport(Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/transports', data: data);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/transports/$id/status', data: {'status': status});
    ref.invalidateSelf();
  }

  Future<void> updatePaiement(int id, String statutPaiement, {double? montantTransport, double? montantPaye}) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/transports/$id/paiement', data: {
      'statut_paiement':   statutPaiement,
      if (montantTransport != null) 'montant_transport': montantTransport,
      if (montantPaye != null)      'montant_paye':      montantPaye,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteTransport(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/transports/$id');
    state = AsyncData(state.value?.where((t) => t.id != id).toList() ?? []);
  }
}

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api      = ref.read(apiClientProvider);
  final response = await api.get('/dashboard/stats');
  return response.data as Map<String, dynamic>;
});

final dashboardAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api      = ref.read(apiClientProvider);
  final response = await api.get('/dashboard/alerts');
  return (response.data['alerts'] as List).cast<Map<String, dynamic>>();
});

final dashboardChartProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api      = ref.read(apiClientProvider);
  final response = await api.get('/dashboard/chart');
  return (response.data['chart'] as List).cast<Map<String, dynamic>>();
});

final trucksOnMissionProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api      = ref.read(apiClientProvider);
  final response = await api.get('/trucks', params: {'status': 'on_mission', 'per_page': '50'});
  final data     = response.data;
  final List items = data['data'] ?? data ?? [];
  return items.cast<Map<String, dynamic>>();
});
