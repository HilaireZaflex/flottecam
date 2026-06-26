import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/models/operation_model.dart';

// ── Provider liste opérations ─────────────────────────────────────────────────

final operationsProvider = AsyncNotifierProviderFamily<OperationsNotifier, List<OperationModel>, String>(
  OperationsNotifier.new,
);

class OperationsNotifier extends FamilyAsyncNotifier<List<OperationModel>, String> {
  @override
  Future<List<OperationModel>> build(String filter) async {
    return _fetchOperations(filter);
  }

  Future<List<OperationModel>> _fetchOperations(String filter) async {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{};
    if (filter.isNotEmpty) {
      // filter peut être "type=recette", "type=depense", "truck_id=1", etc.
      for (final part in filter.split('&')) {
        final kv = part.split('=');
        if (kv.length == 2) params[kv[0]] = kv[1];
      }
    }
    final response = await api.get('/operations', params: params);
    final data = response.data as Map<String, dynamic>;
    return (data['operations'] as List)
        .map((e) => OperationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createOperation(Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    await api.post('/operations', data: data);
    state = AsyncData(await _fetchOperations(arg));
  }

  Future<void> deleteOperation(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/operations/$id');
    state = AsyncData(await _fetchOperations(arg));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchOperations(arg));
  }
}

// ── Provider totaux (bénéfice) ────────────────────────────────────────────────

final operationsTotauxProvider = FutureProvider.family<Map<String, double>, String>((ref, filter) async {
  final api = ref.read(apiClientProvider);
  final params = <String, dynamic>{};
  if (filter.isNotEmpty) {
    for (final part in filter.split('&')) {
      final kv = part.split('=');
      if (kv.length == 2) params[kv[0]] = kv[1];
    }
  }
  final response = await api.get('/operations', params: params);
  final data = response.data as Map<String, dynamic>;
  final totaux = data['totaux'] as Map<String, dynamic>;
  return {
    'recettes': (totaux['recettes'] as num).toDouble(),
    'depenses': (totaux['depenses'] as num).toDouble(),
    'benefice': (totaux['benefice'] as num).toDouble(),
  };
});

// ── Provider stats par camion ─────────────────────────────────────────────────

final rentabiliteParCamionProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/dashboard/rentabilite');
  final data = response.data as Map<String, dynamic>;
  return (data['rentabilite'] as List).cast<Map<String, dynamic>>();
});

// ── Provider dépenses par catégorie ──────────────────────────────────────────

final depensesParCategorieProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/dashboard/depenses-categorie');
  final data = response.data as Map<String, dynamic>;
  return (data['categories'] as List).cast<Map<String, dynamic>>();
});

// ── Provider dettes clients ───────────────────────────────────────────────────

final clientDettesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/operations/clients/dettes');
  final data = response.data as Map<String, dynamic>;
  return (data['dettes'] as List).cast<Map<String, dynamic>>();
});
