// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$tasksRoute];

RouteBase get $tasksRoute => GoRouteData.$route(
  path: '/tasks',
  hasOverriddenOnExit: false,
  factory: $TasksRoute._fromState,
);

mixin $TasksRoute on GoRouteData {
  static TasksRoute _fromState(GoRouterState state) => TasksRoute();

  @override
  String get location => GoRouteData.$location('/tasks');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
