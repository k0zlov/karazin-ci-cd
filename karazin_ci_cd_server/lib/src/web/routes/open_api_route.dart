import 'dart:convert';

import 'package:serverpod/serverpod.dart';

class OpenApiRoute extends Route {
  @override
  Future<Result> handleCall(
    Session session,
    Request request,
  ) async {
    final specification = {
      'openapi': '3.0.3',

      'info': {
        'title': 'Karazin CI/CD API',
        'version': '1.0.0',
        'description': 'REST API built with Serverpod',
      },

      'servers': [
        {
          'url': 'http://localhost:8082',
        },
      ],

      'paths': {
        '/api/tasks': {
          'get': {
            'summary': 'Get all tasks',
            'responses': {
              '200': {
                'description': 'List of tasks',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'array',
                      'items': {
                        r'$ref': '#/components/schemas/Task',
                      },
                    },
                  },
                },
              },
            },
          },

          'post': {
            'summary': 'Create task',
            'requestBody': {
              'required': true,
              'content': {
                'application/json': {
                  'schema': {
                    r'$ref': '#/components/schemas/CreateTask',
                  },
                },
              },
            },
            'responses': {
              '201': {
                'description': 'Task created',
                'content': {
                  'application/json': {
                    'schema': {
                      r'$ref': '#/components/schemas/Task',
                    },
                  },
                },
              },
              '400': {
                'description': 'Invalid request',
              },
            },
          },
        },

        '/api/tasks/{id}': {
          'get': {
            'summary': 'Get task by id',
            'parameters': [
              {
                'name': 'id',
                'in': 'path',
                'required': true,
                'schema': {
                  'type': 'integer',
                },
              },
            ],
            'responses': {
              '200': {
                'description': 'Task found',
                'content': {
                  'application/json': {
                    'schema': {
                      r'$ref': '#/components/schemas/Task',
                    },
                  },
                },
              },
              '404': {
                'description': 'Task not found',
              },
            },
          },

          'put': {
            'summary': 'Update task',
            'parameters': [
              {
                'name': 'id',
                'in': 'path',
                'required': true,
                'schema': {
                  'type': 'integer',
                },
              },
            ],
            'requestBody': {
              'required': true,
              'content': {
                'application/json': {
                  'schema': {
                    r'$ref': '#/components/schemas/UpdateTask',
                  },
                },
              },
            },
            'responses': {
              '200': {
                'description': 'Task updated',
              },
              '404': {
                'description': 'Task not found',
              },
            },
          },

          'delete': {
            'summary': 'Delete task',
            'parameters': [
              {
                'name': 'id',
                'in': 'path',
                'required': true,
                'schema': {
                  'type': 'integer',
                },
              },
            ],
            'responses': {
              '204': {
                'description': 'Task deleted',
              },
              '404': {
                'description': 'Task not found',
              },
            },
          },
        },
      },

      'components': {
        'schemas': {
          'Task': {
            'type': 'object',
            'required': [
              'id',
              'title',
              'completed',
              'createdAt',
            ],
            'properties': {
              'id': {
                'type': 'integer',
                'example': 1,
              },
              'title': {
                'type': 'string',
                'example': 'Learn Serverpod',
              },
              'description': {
                'type': 'string',
                'nullable': true,
                'example': 'Implement REST CRUD',
              },
              'completed': {
                'type': 'boolean',
                'example': false,
              },
              'createdAt': {
                'type': 'string',
                'format': 'date-time',
              },
            },
          },

          'CreateTask': {
            'type': 'object',
            'required': [
              'title',
            ],
            'properties': {
              'title': {
                'type': 'string',
                'example': 'Learn Serverpod',
              },
              'description': {
                'type': 'string',
                'nullable': true,
              },
              'completed': {
                'type': 'boolean',
                'default': false,
              },
            },
          },

          'UpdateTask': {
            'type': 'object',
            'properties': {
              'title': {
                'type': 'string',
              },
              'description': {
                'type': 'string',
                'nullable': true,
              },
              'completed': {
                'type': 'boolean',
              },
            },
          },
        },
      },
    };

    return Response.ok(
      body: Body.fromString(
        jsonEncode(specification),
        mimeType: MimeType.json,
      ),
    );
  }
}
