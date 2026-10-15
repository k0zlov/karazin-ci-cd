import 'dart:convert';

import 'package:karazin_ci_cd_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class TaskRoute extends Route {
  TaskRoute()
    : super(
        methods: {
          Method.get,
          Method.put,
          Method.delete,
        },
      );
  static const _idParam = IntPathParam(#id);

  @override
  Future<Result> handleCall(
    Session session,
    Request request,
  ) async {
    final id = request.pathParameters.get(_idParam);

    switch (request.method) {
      case Method.get:
        return _getById(session, id);

      case Method.put:
        return _update(session, request, id);

      case Method.delete:
        return _delete(session, id);

      default:
        return Response.forbidden();
    }
  }

  Future<Result> _getById(
    Session session,
    int id,
  ) async {
    final task = await Task.db.findById(
      session,
      id,
    );

    if (task == null) {
      return _notFound();
    }

    return _jsonResponse(task.toJson());
  }

  Future<Result> _update(
    Session session,
    Request request,
    int id,
  ) async {
    final task = await Task.db.findById(
      session,
      id,
    );

    if (task == null) {
      return _notFound();
    }

    final body = await request.readAsString();

    final json = jsonDecode(body) as Map<String, dynamic>;

    final updatedTask = task.copyWith(
      title: json['title'] as String? ?? task.title,
      description: json.containsKey('description')
          ? json['description'] as String?
          : task.description,
      completed: json['completed'] as bool? ?? task.completed,
    );

    final result = await Task.db.updateRow(
      session,
      updatedTask,
    );

    return _jsonResponse(result.toJson());
  }

  Future<Result> _delete(
    Session session,
    int id,
  ) async {
    final task = await Task.db.findById(
      session,
      id,
    );

    if (task == null) {
      return _notFound();
    }

    await Task.db.deleteRow(
      session,
      task,
    );

    return Response.noContent();
  }

  Response _jsonResponse(Object? data) {
    return Response.ok(
      body: Body.fromString(
        jsonEncode(data),
        mimeType: MimeType.json,
      ),
    );
  }

  Response _notFound() {
    return Response.notFound(
      body: Body.fromString(
        jsonEncode({
          'error': 'Task not found',
        }),
        mimeType: MimeType.json,
      ),
    );
  }
}
