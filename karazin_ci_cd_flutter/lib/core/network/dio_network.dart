import 'package:dio/dio.dart';

import 'package:karazin_ci_cd_flutter/core/network/network.dart';

class DioNetwork(final Dio _dio) implements Network {
  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<T>(path, queryParameters: queryParameters);

    return response.data as T;
  }

  @override
  Future<T> post<T>(String path, {Object? data}) async {
    final response = await _dio.post<T>(path, data: data);

    return response.data as T;
  }

  @override
  Future<T> put<T>(String path, {Object? data}) async {
    final response = await _dio.put<T>(path, data: data);

    return response.data as T;
  }

  @override
  Future<T> patch<T>(String path, {Object? data}) async {
    final response = await _dio.patch<T>(path, data: data);

    return response.data as T;
  }

  @override
  Future<void> delete(String path) async {
    await _dio.delete<void>(path);
  }
}
