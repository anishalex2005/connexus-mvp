import 'package:flutter/foundation.dart';

import '../../core/constants/call_constants.dart';
import '../../data/repositories/call_repository.dart';
import '../../data/services/telnyx_service.dart';
import '../models/call_model.dart';
import '../models/call_record.dart';

/// Use case for logging an ended call (hang up / remote end / failure).
///
/// This does **not** perform the low-level hangup; that is handled by
/// `TelnyxService.hangup` and the Active Call BLoC. This use case focuses on
/// persisting a `CallRecord` with duration and end reason.
class EndCallUseCase {
  final TelnyxService _telnyxService;
  final CallRepository _callRepository;

  EndCallUseCase({
    required TelnyxService telnyxService,
    required CallRepository callRepository,
  })  : _telnyxService = telnyxService,
        _callRepository = callRepository;

  /// Logs an ended call to the history repository.
  ///
  /// [duration] is the total talk time; [reason] distinguishes scenarios
  /// such as user hang up vs. network failure.
  Future<void> execute({
    required Duration duration,
    required CallEndReason reason,
  }) async {
    try {
      debugPrint('EndCallUseCase: Logging ended call (reason=${reason.name})');

      final Map<String, dynamic>? callInfo =
          _telnyxService.getCurrentCallInfo();

      if (callInfo == null) {
        debugPrint(
          'EndCallUseCase: No current call info available, skipping log',
        );
        return;
      }

      final String directionString =
          (callInfo['direction'] as String?) ?? 'incoming';

      final CallRecord record = CallRecord(
        id: (callInfo['callId'] as String?) ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        callerNumber:
            (callInfo['callerNumber'] as String?) ?? 'Unknown',
        callerName: callInfo['callerName'] as String?,
        direction: directionString == 'outgoing'
            ? CallDirection.outgoing
            : CallDirection.incoming,
        status: _mapReasonToStatus(reason, duration),
        declineReason: null,
        endReason: reason.name,
        timestamp: DateTime.now(),
        duration: duration,
      );

      await _callRepository.saveCallRecord(record);
      debugPrint('EndCallUseCase: Call logged successfully');
    } catch (e, stackTrace) {
      // Logging failures should not break the hang up flow.
      debugPrint('EndCallUseCase: Error logging ended call: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  CallStatus _mapReasonToStatus(
    CallEndReason reason,
    Duration duration,
  ) {
    final bool hasTalkTime = duration.inSeconds > 0;

    switch (reason) {
      case CallEndReason.declined:
        return CallStatus.declined;
      case CallEndReason.noAnswer:
        return CallStatus.missed;
      case CallEndReason.networkError:
      case CallEndReason.connectionFailed:
        return hasTalkTime ? CallStatus.completed : CallStatus.failed;
      case CallEndReason.transferred:
      case CallEndReason.userHangUp:
      case CallEndReason.remoteHangUp:
      case CallEndReason.unknown:
        return hasTalkTime ? CallStatus.completed : CallStatus.answered;
    }
  }
}


