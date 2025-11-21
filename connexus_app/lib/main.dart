import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'injection.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app configuration for development
  await AppConfig.initialize(Environment.development);

  // Configure dependency injection
  await configureDependencies();

  // Log app start
  Logger.info('Starting ConnexUS App...');

  // Run app
  runApp(const ConnexUSApp());
}

