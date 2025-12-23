import 'package:flutter/foundation.dart';

import '../../data/repositories/call_repository.dart';
import '../../data/services/telnyx_service.dart';
import '../models/call_model.dart';
import '../models/call_record.dart';

/// Use case for declining incoming calls.
///
/// Handles the business logic of rejecting a call and logging the action.
class DeclineCallUseCase {
  final TelnyxService _telnyxService;
  final CallRepository _callRepository;

  DeclineCallUseCase({
    required TelnyxService telnyxService,
    required CallRepository callRepository,
  })  : _telnyxService = telnyxService,
        _callRepository = callRepository;

  /// Executes the decline call action.
  ///
  /// [reason] - Optional reason for declining (e.g., "busy", "user_declined").
  /// Returns a [DeclineCallResult] indicating success or failure.
  Future<DeclineCallResult> execute({String? reason}) async {
    try {
      debugPrint('DeclineCallUseCase: Starting decline process');

      // Get call info before declining (for logging).
      final Map<String, dynamic>? callInfo =
          _telnyxService.getCurrentCallInfo();

      // Perform the decline action.
      final bool success =
          await _telnyxService.declineCall(reason: reason);

      if (!success) {
        return DeclineCallResult(
          success: false,
          error: 'Failed to decline call via TelnyxService',
        );
      }

      // Log the declined call.
      if (callInfo != null) {
        await _logDeclinedCall(callInfo, reason);
      }

      debugPrint('DeclineCallUseCase: Call declined successfully');

      return DeclineCallResult(
        success: true,
        callId: callInfo?['callId'] as String?,
      );
    } catch (e, stackTrace) {
      debugPrint('DeclineCallUseCase: Error: $e');
      debugPrint('Stack trace: $stackTrace');

      return DeclineCallResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Logs the declined call to the repository.
  Future<void> _logDeclinedCall(
    Map<String, dynamic> callInfo,
    String? reason,
  ) async {
    try {
      final CallRecord callRecord = CallRecord(
        id: (callInfo['callId'] as String?) ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        callerNumber:
            (callInfo['callerNumber'] as String?) ?? 'Unknown',
        callerName: callInfo['callerName'] as String?,
        direction: (callInfo['direction'] as String?) == 'outgoing'
            ? CallDirection.outgoing
            : CallDirection.incoming,
        status: CallStatus.declined,
        declineReason: reason ?? 'user_declined',
        endReason: CallStatus.declined.name,
        timestamp: DateTime.now(),
        // Declined calls have no talk time duration.
        duration: Duration.zero,
      );

      await _callRepository.saveCallRecord(callRecord);
      debugPrint('DeclineCallUseCase: Call logged to repository');
    } catch (e) {
      // Don't fail the decline if logging fails.
      debugPrint('DeclineCallUseCase: Failed to log call: $e');
    }
  }
}

/// Result class for decline call operation.
class DeclineCallResult {
  final bool success;
  final String? callId;
  final String? error;

  DeclineCallResult({
    required this.success,
    this.callId,
    this.error,
  });

  @override
  String toString() {
    return 'DeclineCallResult(success: $success, callId: $callId, error: $error)';
  }
}


