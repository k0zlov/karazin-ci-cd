import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:karazin_ci_cd_flutter/core/network/dio_network.dart';
import 'package:karazin_ci_cd_flutter/core/network/network.dart';

final GetIt getIt = GetIt.instance;

Future<void> registerDependencies() async {
  const configuredUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8082');

  final dio = Dio();
  final runtimeUrl = kIsWeb ? await _readRuntimeApiUrl(dio) : null;
  dio.options.baseUrl = runtimeUrl ?? configuredUrl;
  getIt.registerLazySingleton<Network>(() => DioNetwork(dio));
}

Future<String?> _readRuntimeApiUrl(Dio dio) async {
  try {
    final response = await dio.getUri<String>(
      Uri.base.resolve('api-base-url.txt'),
      options: Options(responseType: ResponseType.plain, headers: {'Cache-Control': 'no-cache'}),
    );
    final url = response.data?.trim();
    return url == null || url.isEmpty ? null : url;
  } on DioException {
    return null;
  }
}
