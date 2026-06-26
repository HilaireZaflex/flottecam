import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final monthlyReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, month) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/reports/monthly', params: {'month': month});
  return response.data as Map<String, dynamic>;
});
