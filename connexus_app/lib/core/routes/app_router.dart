import 'package:flutter/material.dart';
import '../../presentation/screens/splash/splash_screen.dart';

/// Application routing configuration
class AppRouter {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String call = '/call';
  static const String incomingCall = '/incoming-call';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String callHistory = '/call-history';
  static const String aiConfig = '/ai-config';
  static const String smsTemplates = '/sms-templates';
  
  /// Generate route based on settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  /// Navigate to a named route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
  
  /// Replace current route with a named route
  static Future<T?> navigateAndReplace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
  
  /// Clear stack and navigate to a named route
  static Future<T?> navigateAndClearStack<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  /// Pop current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
  
  /// Pop until a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
}


