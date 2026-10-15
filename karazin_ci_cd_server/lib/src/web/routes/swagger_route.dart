import 'package:serverpod/serverpod.dart';

class SwaggerRoute extends Route {
  @override
  Future<Result> handleCall(
    Session session,
    Request request,
  ) async {
    const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">

  <title>Karazin CI/CD API</title>

  <link
    rel="stylesheet"
    href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css"
  >
</head>

<body>

<div id="swagger-ui"></div>

<script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>

<script>
  SwaggerUIBundle({
    url: '/openapi.json',
    dom_id: '#swagger-ui',
  });
</script>

</body>
</html>
''';

    return Response.ok(
      body: Body.fromString(
        html,
        mimeType: MimeType.html,
      ),
    );
  }
}