import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/call_colors.dart';
import '../../../domain/models/call_model.dart';
import '../../providers/call_provider.dart';

/// Screen displayed during an active call.
///
/// This is a lightweight placeholder for Task 22 that shows:
/// - caller information
/// - basic call status
/// - call duration timer
/// - end call button
class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (BuildContext context, CallProvider callProvider, _) {
        final CallModel? call = callProvider.currentCall;

        if (call == null) {
          // If there is no active call, just pop back.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  CallColors.backgroundStart,
                  CallColors.backgroundEnd,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Text(
                    _statusText(call.state),
                    style: const TextStyle(
                      color: CallColors.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    call.displayName,
                    style: const TextStyle(
                      color: CallColors.primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (call.callerName != null)
                    Text(
                      call.formattedNumber,
                      style: const TextStyle(
                        color: CallColors.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(call.duration),
                    style: const TextStyle(
                      color: CallColors.answerGreen,
                      fontSize: 22,
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: _buildEndCallButton(context, callProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEndCallButton(
    BuildContext context,
    CallProvider callProvider,
  ) {
    return Material(
      color: CallColors.declineRed,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await callProvider.endCall();
          if (Navigator.canPop(context)) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        },
        child: const SizedBox(
          width: 72,
          height: 72,
          child: Icon(
            Icons.call_end,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  String _statusText(CallState state) {
    switch (state) {
      case CallState.incoming:
        return 'Ringing';
      case CallState.connecting:
        return 'Connecting...';
      case CallState.active:
        return 'In Call';
      case CallState.held:
        return 'On Hold';
      case CallState.ended:
        return 'Call Ended';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '00:00';
    }

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
