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
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppConfig.initialize(Environment.development);
  await configureDependencies();
  await initializeServices();

  Logger.info('Starting ConnexUS App (development)...');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CallProvider>(
          create: (_) => CallProvider(),
        ),
      ],
      child: TelnyxInitializer(
        onInitialized: () {
          Logger.info('ConnexUS (dev): Telnyx SDK ready');
        },
        onError: (String error) {
          Logger.error('ConnexUS (dev): Telnyx initialization error - $error');
        },
        child: const ConnexUSApp(),
      ),
    ),
  );
}
