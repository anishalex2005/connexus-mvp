import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class ConnexUSApp extends StatelessWidget {
  const ConnexUSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: const [
        // Add BLoC providers here as they're implemented
        // BlocProvider(create: (context) => getIt<AuthBloc>()),
      ],
      child: MaterialApp(
        title: 'ConnexUS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}



