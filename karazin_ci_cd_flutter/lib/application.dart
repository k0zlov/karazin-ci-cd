import 'package:flutter/material.dart';
import 'package:karazin_ci_cd_flutter/core/navigation/router.dart';

class Application extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}
