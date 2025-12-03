/// Permission Handler Service
///
/// Manages runtime permissions required for VoIP functionality.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of permission request.
enum PermissionResult {
  /// All permissions granted.
  granted,

  /// Some permissions denied but app can function.
  partiallyGranted,

  /// Critical permissions denied.
  denied,

  /// User permanently denied, must go to settings.
  permanentlyDenied,
}

/// Service for handling app permissions.
class PermissionService {
  /// Singleton instance.
  static final PermissionService _instance = PermissionService._internal();

  /// Get the singleton instance.
  static PermissionService get instance => _instance;

  PermissionService._internal();

  /// Required permissions for VoIP calls.
  static const List<Permission> _requiredPermissions = <Permission>[
    Permission.microphone,
  ];

  /// Optional permissions that enhance functionality.
  static List<Permission> get _optionalPermissions => <Permission>[
        Permission.phone,
        Permission.bluetooth,
        if (Platform.isAndroid) Permission.bluetoothConnect,
      ];

  /// Check if all required permissions are granted.
  Future<bool> hasRequiredPermissions() async {
    for (final Permission permission in _requiredPermissions) {
      final PermissionStatus status = await permission.status;
      if (!status.isGranted) {
        debugPrint(
          'PermissionService: Missing required permission: $permission',
        );
        return false;
      }
    }
    return true;
  }

  /// Request all required permissions for VoIP.
  ///
  /// Returns [PermissionResult] indicating the outcome.
  Future<PermissionResult> requestVoIPPermissions() async {
    debugPrint('PermissionService: Requesting VoIP permissions...');

    // Check current status first.
    final PermissionResult currentStatus = await _checkAllPermissions();
    if (currentStatus == PermissionResult.granted) {
      debugPrint('PermissionService: All permissions already granted');
      return PermissionResult.granted;
    }

    // Request required permissions.
    final Map<Permission, PermissionStatus> requiredResults =
        await _requiredPermissions.request();

    // Check if any required permission was denied.
    var anyPermanentlyDenied = false;
    var anyDenied = false;

    for (final MapEntry<Permission, PermissionStatus> entry
        in requiredResults.entries) {
      debugPrint('PermissionService: ${entry.key} -> ${entry.value}');

      if (entry.value.isPermanentlyDenied) {
        anyPermanentlyDenied = true;
      } else if (!entry.value.isGranted) {
        anyDenied = true;
      }
    }

    if (anyPermanentlyDenied) {
      debugPrint('PermissionService: Some permissions permanently denied');
      return PermissionResult.permanentlyDenied;
    }

    if (anyDenied) {
      debugPrint('PermissionService: Some permissions denied');
      return PermissionResult.denied;
    }

    // Request optional permissions (non-blocking).
    await _requestOptionalPermissions();

    debugPrint('PermissionService: All required permissions granted');
    return PermissionResult.granted;
  }

  /// Request optional permissions without blocking.
  Future<void> _requestOptionalPermissions() async {
    debugPrint('PermissionService: Requesting optional permissions...');

    for (final Permission permission in _optionalPermissions) {
      try {
        final PermissionStatus status = await permission.request();
        debugPrint('PermissionService: Optional $permission -> $status');
      } catch (e) {
        // Ignore errors for optional permissions.
        debugPrint('PermissionService: Failed to request $permission: $e');
      }
    }
  }

  /// Check all permission statuses.
  Future<PermissionResult> _checkAllPermissions() async {
    var allGranted = true;

    for (final Permission permission in _requiredPermissions) {
      final PermissionStatus status = await permission.status;
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    return allGranted ? PermissionResult.granted : PermissionResult.denied;
  }

  /// Request microphone permission specifically.
  Future<bool> requestMicrophonePermission() async {
    debugPrint('PermissionService: Requesting microphone permission...');

    final PermissionStatus status = await Permission.microphone.request();
    debugPrint('PermissionService: Microphone permission: $status');

    return status.isGranted;
  }

  /// Check if microphone permission is granted.
  Future<bool> hasMicrophonePermission() async {
    final PermissionStatus status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Open app settings for manual permission management.
  Future<bool> openSettings() async {
    debugPrint('PermissionService: Opening app settings...');
    return openAppSettings();
  }

  /// Get a human-readable message for permission result.
  String getPermissionMessage(PermissionResult result) {
    switch (result) {
      case PermissionResult.granted:
        return 'All permissions granted. Ready to make calls.';
      case PermissionResult.partiallyGranted:
        return 'Some permissions granted. Some features may be limited.';
      case PermissionResult.denied:
        return 'Microphone permission is required to make calls. '
            'Please grant permission to continue.';
      case PermissionResult.permanentlyDenied:
        return 'Microphone permission was denied. '
            'Please enable it in Settings to make calls.';
    }
  }
}
