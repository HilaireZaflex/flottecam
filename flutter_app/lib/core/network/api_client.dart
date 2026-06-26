import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(storageServiceProvider);
  return ApiClient(storage);
});

class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;

  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('Délai de connexion dépassé.');
      case DioExceptionType.connectionError:
        return AppException('Pas de connexion internet.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        String msg  = 'Une erreur est survenue.';
        if (data is Map) {
          msg = data['message'] as String? ?? msg;
          if (data['errors'] is Map) {
            final errors = data['errors'] as Map;
            msg = errors.values.first is List
                ? errors.values.first.first.toString()
                : errors.values.first.toString();
          }
        }
        return AppException(msg, statusCode: code);
      default:
        return AppException('Erreur inattendue.');
    }
  }
}

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        // 401 → token expiré, nettoyer le stockage
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: AppConstants.tokenKey);
          await _storage.delete(key: AppConstants.userKey);
        }
        handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try { return await _dio.get(path, queryParameters: params); }
    on DioException catch (e) { throw AppException.fromDio(e); }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try { return await _dio.post(path, data: data); }
    on DioException catch (e) { throw AppException.fromDio(e); }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try { return await _dio.put(path, data: data); }
    on DioException catch (e) { throw AppException.fromDio(e); }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try { return await _dio.patch(path, data: data); }
    on DioException catch (e) { throw AppException.fromDio(e); }
  }

  Future<Response> delete(String path) async {
    try { return await _dio.delete(path); }
    on DioException catch (e) { throw AppException.fromDio(e); }
  }

  Future<Response> postForm(String path, FormData data) async {
    try {
      return await _dio.post(path, data: data,
          options: Options(contentType: 'multipart/form-data'));
    } on DioException catch (e) { throw AppException.fromDio(e); }
  }
}
