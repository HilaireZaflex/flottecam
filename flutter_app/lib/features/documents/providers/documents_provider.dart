import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/models/document_model.dart';

final documentsProvider = AsyncNotifierProviderFamily<DocumentsNotifier, List<DocumentModel>, String>(
  DocumentsNotifier.new,
);

class DocumentsNotifier extends FamilyAsyncNotifier<List<DocumentModel>, String> {
  @override
  Future<List<DocumentModel>> build(String filter) async {
    return _fetch();
  }

  Future<List<DocumentModel>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{};
    if (arg.isNotEmpty) {
      // Gérer les valeurs avec backslash (ex: App\Models\Truck)
      final eqIdx = arg.indexOf('=');
      if (eqIdx > 0) {
        params[arg.substring(0, eqIdx)] = arg.substring(eqIdx + 1);
      }
    }
    final response = await api.get('/documents', params: params);
    final raw = response.data;
    List list = [];
    if (raw is Map) {
      list = (raw['documents'] ?? raw['data'] ?? []) as List;
    } else if (raw is List) {
      list = raw;
    }
    return list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteDocument(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/documents/$id');
    state = AsyncData(await _fetch());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}
