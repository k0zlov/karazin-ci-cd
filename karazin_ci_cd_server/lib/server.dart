import 'package:karazin_ci_cd_server/src/generated/serverpod.dart';
import 'package:karazin_ci_cd_server/src/web/routes/open_api_route.dart';
import 'package:karazin_ci_cd_server/src/web/routes/swagger_route.dart';
import 'package:karazin_ci_cd_server/src/web/routes/task_route.dart';
import 'package:karazin_ci_cd_server/src/web/routes/tasks_route.dart';

// Redundant commentary
void run(List<String> args) async {
  final pod = Serverpod(args);

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
