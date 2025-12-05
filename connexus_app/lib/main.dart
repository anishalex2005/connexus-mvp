import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'injection.dart';
import 'presentation/providers/call_provider.dart';
import 'presentation/widgets/telnyx_initializer.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations.
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app configuration for development.
  await AppConfig.initialize(Environment.development);

  // Configure dependency injection.
  await configureDependencies();

  // Initialize core background services (network monitoring, call handler).
  await initializeServices();

  // Log app start.
  Logger.info('Starting ConnexUS App...');

  // Run app wrapped with providers and Telnyx initializer.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CallProvider>(
          create: (_) => CallProvider(),
        ),
      ],
      child: TelnyxInitializer(
        onInitialized: () {
          Logger.info('ConnexUS: Telnyx SDK ready');
        },
        onError: (String error) {
          Logger.error('ConnexUS: Telnyx initialization error - $error');
        },
        child: const ConnexUSApp(),
      ),
    ),
  );
}
