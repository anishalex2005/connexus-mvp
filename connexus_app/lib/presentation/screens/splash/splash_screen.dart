import 'package:flutter/material.dart';
import '../base_screen.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/utils/logger.dart';

class SplashScreen extends BaseScreen {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends BaseScreenState<SplashScreen> {
  @override
  bool get showAppBar => false;
  
  @override
  Color get backgroundColor => Theme.of(context).primaryColor;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    Logger.info('Initializing app...');
    
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Navigate to appropriate screen (placeholder)
    if (mounted) {
      Logger.info('App initialized successfully');
      // AppRouter.navigateAndReplace(context, AppRouter.login);
    }
  }
  
  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.phone_in_talk,
              size: 60,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ConnexUS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI-Powered Calling',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}



