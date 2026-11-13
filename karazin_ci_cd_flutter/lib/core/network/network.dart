abstract interface class Network {
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters});

  Future<T> post<T>(String path, {Object? data});

  Future<T> put<T>(String path, {Object? data});

  Future<T> patch<T>(String path, {Object? data});

  Future<void> delete(String path);
}
