import 'package:karazin_ci_cd_server/src/generated/serverpod.dart';
import 'package:karazin_ci_cd_server/src/web/routes/open_api_route.dart';
import 'package:karazin_ci_cd_server/src/web/routes/swagger_route.dart';
import 'package:karazin_ci_cd_server/src/web/routes/task_route.dart';
import 'package:karazin_ci_cd_server/src/web/routes/tasks_route.dart';

Future<void> run(List<String> args) async {
  final pod = Serverpod(args);

  final cors = createMiddleware(
    onRequest: (request) {
      if (request.method != Method.options) return null;

      return Response.noContent(
        headers: Headers.build((headers) {
          headers['Access-Control-Allow-Origin'] = ['*'];
          headers['Access-Control-Allow-Methods'] = [
            'GET, POST, PUT, DELETE, OPTIONS',
          ];
          headers['Access-Control-Allow-Headers'] = [
            'Content-Type, Authorization',
          ];
        }),
      );
    },
    onResponse: (response) => response.copyWith(
      headers: response.headers.transform((headers) {
        headers['Access-Control-Allow-Origin'] = ['*'];
        headers['Access-Control-Allow-Methods'] = [
          'GET, POST, PUT, DELETE, OPTIONS',
        ];
        headers['Access-Control-Allow-Headers'] = [
          'Content-Type, Authorization',
        ];
      }),
    ),
  );

  pod.webServer.addMiddleware(cors, '/api');

  pod.webServer.addRoute(
    TasksRoute(),
    '/api/tasks',
  );

  pod.webServer.addRoute(
    TaskRoute(),
    '/api/tasks/:id',
  );

  pod.webServer.addRoute(
    OpenApiRoute(),
    '/openapi.json',
  );

  pod.webServer.addRoute(
    SwaggerRoute(),
    '/docs',
  );

  await pod.start();
}
