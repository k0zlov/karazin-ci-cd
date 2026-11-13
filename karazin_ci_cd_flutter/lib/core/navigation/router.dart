import 'package:go_router/go_router.dart';
import 'package:karazin_ci_cd_flutter/core/navigation/routes.dart';

final GoRouter router = GoRouter(routes: $appRoutes, initialLocation: TasksRoute().location);
