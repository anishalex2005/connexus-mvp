import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';

/// Root application widget.
///
/// For the current demo we don't use any BLoCs yet, so we build a plain
/// [MaterialApp] and use the [builder] callback to overlay the environment
/// banner in non-production builds.
class ConnexUSApp extends StatelessWidget {
  const ConnexUSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.debugMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.splash,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        if (AppConfig.isProduction) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              right: 0,
              child: Banner(
                message: AppConfig.environment.name.toUpperCase(),
                location: BannerLocation.topEnd,
                color: AppConfig.isDevelopment ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }
}
