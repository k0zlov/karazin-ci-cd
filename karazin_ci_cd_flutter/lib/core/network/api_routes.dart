abstract final class ApiRoutes {
  static const String tasks = '/api/tasks';

  static String task(int id) => '$tasks/$id';
}
