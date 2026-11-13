import 'package:karazin_ci_cd_server/server.dart' as server;

Future<void> main(List<String> args) async {
  await server.run([
    ...args,
    '--role',
    'maintenance',
    '--apply-migrations',
  ]);
}
