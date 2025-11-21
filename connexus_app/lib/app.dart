import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';

class ConnexUSApp extends StatelessWidget {
  const ConnexUSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget app = MultiBlocProvider(
      providers: const [
        // Add BLoC providers here as they're implemented
        // BlocProvider(create: (context) => getIt<AuthBloc>()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: AppConfig.debugMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
      ),
    );

    if (!AppConfig.isProduction) {
      return Stack(
        children: [
          app,
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
    }

    return app;
  }
}



