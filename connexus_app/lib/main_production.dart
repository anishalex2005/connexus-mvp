import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'injection.dart';
import 'presentation/widgets/telnyx_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppConfig.initialize(Environment.production);
  await configureDependencies();

  runApp(
    const TelnyxInitializer(
      child: ConnexUSApp(),
    ),
  );
}
