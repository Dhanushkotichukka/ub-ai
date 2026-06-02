import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_keys.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ),
    ]);
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final box = Hive.box(HiveKeys.userBox);
    final token = box.get(HiveKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — clear storage and redirect handled by AuthBloc
      Hive.box(HiveKeys.userBox).deleteAll([HiveKeys.accessToken, HiveKeys.refreshToken]);
    }
    handler.next(err);
  }
}
