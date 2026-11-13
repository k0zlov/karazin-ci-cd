import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:karazin_ci_cd_flutter/core/network/dio_network.dart';
import 'package:karazin_ci_cd_flutter/core/network/network.dart';

final GetIt getIt = GetIt.instance;

Future<void> registerDependencies() async {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');

  final dio = Dio();
  final runtimeUrl = kIsWeb ? await _readRuntimeApiUrl(dio) : null;
  final defaultUrl = kIsWeb ? Uri.base.origin : 'http://localhost:8082';
  dio.options.baseUrl =
      runtimeUrl ?? (configuredUrl.isEmpty ? defaultUrl : configuredUrl);
  getIt.registerLazySingleton<Network>(() => DioNetwork(dio));
}

Future<String?> _readRuntimeApiUrl(Dio dio) async {
  try {
    final response = await dio.getUri<String>(
      Uri.base.resolve('/runtime-api-url.txt'),
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Cache-Control': 'no-cache'},
      ),
    );
    final value = response.data?.trim();
    final url = value == null ? null : Uri.tryParse(value);
    if (url == null ||
        url.host.isEmpty ||
        (url.scheme != 'http' && url.scheme != 'https')) {
      return null;
    }
    return url.toString();
  } on DioException {
    return null;
  }
}
