import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppConfig.initialize(Environment.staging);

  runApp(const ConnexUSApp());
}
