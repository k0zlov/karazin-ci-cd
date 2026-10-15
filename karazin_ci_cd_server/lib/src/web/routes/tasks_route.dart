import 'dart:convert';

import 'package:karazin_ci_cd_server/src/generated/protocol.dart';
import 'package:karazin_ci_cd_server/src/modules/tasks/task_validator.dart';
import 'package:serverpod/serverpod.dart';

class TasksRoute extends Route {
  TasksRoute()
    : super(
        methods: {
          Method.get,
          Method.post,
        },
      );

  @override
  Future<Result> handleCall(
    Session session,
    Request request,
  ) async {
    switch (request.method) {
      case Method.get:
        return _getAll(session);

      case Method.post:
        return _create(session, request);

      default:
        return Response.forbidden();
    }
  }

  Future<Result> _getAll(Session session) async {
    final tasks = await Task.db.find(
      session,
      orderBy: (task) => task.createdAt,
    );

    return _jsonResponse(
      tasks.map((task) => task.toJson()).toList(),
    );
  }

  Future<Result> _create(
    Session session,
    Request request,
  ) async {
    final body = await request.readAsString();

    final json = jsonDecode(body) as Map<String, dynamic>;

    final title = json['title'] as String?;

    if (!TaskValidator.isValidTitle(title)) {
      return Response.badRequest(
        body: Body.fromString(
          jsonEncode({
            'error': 'Invalid title',
          }),
          mimeType: MimeType.json,
        ),
      );
    }

    final task = Task(
      title: title!,
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
    );

    final createdTask = await Task.db.insertRow(
      session,
      task,
    );

    return Response(
      201,
      body: Body.fromString(
        jsonEncode(createdTask.toJson()),
        mimeType: MimeType.json,
      ),
    );
  }

  Response _jsonResponse(Object? data) {
    return Response.ok(
      body: Body.fromString(
        jsonEncode(data),
        mimeType: MimeType.json,
      ),
    );
  }
}
