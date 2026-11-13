import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karazin_ci_cd_flutter/di_container.dart';
import 'package:karazin_ci_cd_flutter/features/tasks/view/screens/tasks_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<TasksRoute>(path: '/tasks')
class TasksRoute extends GoRouteData with $TasksRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TasksScreen(network: getIt());
  }
}
