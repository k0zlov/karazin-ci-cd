import 'package:flutter/material.dart';
import 'package:karazin_ci_cd_flutter/application.dart';
import 'package:karazin_ci_cd_flutter/di_container.dart';

Future<void> main() async {
  await registerDependencies();

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const Application());
}
