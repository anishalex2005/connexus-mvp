/// Telnyx Initializer Widget
///
/// A wrapper widget that handles Telnyx SDK initialization
/// and permission requests on app startup.
library;

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/telnyx_service.dart';
import '../../injection.dart';

/// Widget that initializes Telnyx SDK when the app starts.
class TelnyxInitializer extends StatefulWidget {
  /// The child widget to display after initialization.
  final Widget child;

  /// Optional callback when initialization completes.
  final VoidCallback? onInitialized;

  /// Optional callback when initialization fails.
  final void Function(String error)? onError;

  const TelnyxInitializer({
    super.key,
    required this.child,
    this.onInitialized,
    this.onError,
  });

  @override
  State<TelnyxInitializer> createState() => _TelnyxInitializerState();
}

class _TelnyxInitializerState extends State<TelnyxInitializer> {
  bool _isInitializing = true;
  String? _error;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeTelnyx();
  }

  Future<void> _initializeTelnyx() async {
    try {
      debugPrint('TelnyxInitializer: Starting initialization...');

      // Step 1: Check and request permissions.
      final PermissionResult permissionResult =
          await PermissionService.instance.requestVoIPPermissions();

      if (permissionResult == PermissionResult.permanentlyDenied) {
        setState(() {
          _error = 'Microphone permission permanently denied. '
              'Please enable in Settings.';
          _isInitializing = false;
        });
        widget.onError?.call(_error!);
        return;
      }

      if (permissionResult == PermissionResult.denied) {
        setState(() {
          _error = 'Microphone permission is required for calls.';
          _isInitializing = false;
        });
        widget.onError?.call(_error!);
        return;
      }

      _permissionsGranted = true;
      debugPrint('TelnyxInitializer: Permissions granted');

      // Step 2: Check if Telnyx config exists (environment gating).
      if (!AppConfig.hasTelnyxConfig) {
        debugPrint('TelnyxInitializer: No Telnyx config - skipping SDK init');
        setState(() {
          _isInitializing = false;
        });
        widget.onInitialized?.call();
        return;
      }

      // Step 3: Attempt to connect using any stored SIP credentials.
      final telnyxService = getIt<TelnyxService>();
      await telnyxService.connectWithStoredCredentials();

      debugPrint('TelnyxInitializer: Telnyx connection attempt started');

      setState(() {
        _isInitializing = false;
      });

      widget.onInitialized?.call();
    } catch (e, stackTrace) {
      debugPrint('TelnyxInitializer: Error - $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _error = 'Initialization error: $e';
        _isInitializing = false;
      });

      widget.onError?.call(_error!);
    }
  }

  Future<void> _retryPermissions() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    await _initializeTelnyx();
  }

  void _openSettings() {
    PermissionService.instance.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading during initialization.
    if (_isInitializing) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Initializing ConnexUS...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error screen if initialization failed.
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Initialization Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (!_permissionsGranted) ...<Widget>[
                    ElevatedButton(
                      onPressed: _retryPermissions,
                      child: const Text('Request Permissions'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _openSettings,
                      child: const Text('Open Settings'),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: _retryPermissions,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Initialization successful - show the app.
    return widget.child;
  }
}
