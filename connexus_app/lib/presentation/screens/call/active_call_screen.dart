import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/call_constants.dart';
import '../../../data/services/audio_control_service.dart';
import '../../../domain/models/call_model.dart';
import '../../../injection.dart';
import '../../bloc/active_call/active_call_bloc.dart';
import '../../bloc/active_call/active_call_event.dart';
import '../../bloc/active_call/active_call_state.dart';
import '../../providers/audio_control_provider.dart';
import '../../providers/call_provider.dart';
import '../../widgets/call/audio_control_row.dart';
import '../../widgets/call/call_control_button.dart';
import '../../widgets/call/call_quality_indicator.dart';
import '../../widgets/call/dtmf_keypad.dart';
import 'call_ended_screen.dart';

/// Main screen displayed during an active call.
/// Provides call information, controls, and DTMF keypad.
class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // Set preferred orientations for call screen.
    SystemChrome.setPreferredOrientations(
      const <DeviceOrientation>[DeviceOrientation.portraitUp],
    );

    _initializeCallState();

    // Background animation for visual appeal.
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Color(0xFF1A1A2E),
      end: Color(0xFF16213E),
    ).animate(_backgroundAnimationController);
  }

  void _initializeCallState() {
    // Use existing CallProvider call context as the source of truth.
    final CallProvider callProvider =
        context.read<CallProvider>();
    final CallModel? call = callProvider.currentCall;

    if (call == null) {
      // No active call; close this screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
      return;
    }

    context.read<ActiveCallBloc>().add(
          CallBecameActive(
            callId: call.callId,
            callerName: call.displayName,
            callerNumber: call.formattedNumber,
            callerAvatarUrl: call.callerPhotoUrl,
          ),
        );
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    // Reset orientations.
    SystemChrome.setPreferredOrientations(
      const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AudioControlProvider>(
      create: (BuildContext context) =>
          AudioControlProvider(audioService: getIt<AudioControlService>())
            ..initialize(),
      child: BlocConsumer<ActiveCallBloc, ActiveCallState>(
        listener: (BuildContext context, ActiveCallState state) {
          if (state is ActiveCallComplete) {
            // When the call completes, navigate to a summary screen.
            final CallProvider callProvider =
                context.read<CallProvider>();
            final CallModel? call = callProvider.currentCall;

            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => CallEndedScreen(
                  call: call,
                  endReason: _inferEndReason(state.endReason),
                  duration: state.totalDuration,
                ),
              ),
            );
          } else if (state is ActiveCallError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (BuildContext context, ActiveCallState state) {
          if (state is! ActiveCallInProgress) {
            return const Scaffold(
              backgroundColor: Color(0xFF1A1A2E),
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            );
          }

          return AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (BuildContext context, Widget? child) {
              return Scaffold(
                backgroundColor: _backgroundAnimation.value,
                body: SafeArea(
                  child: Column(
                    children: <Widget>[
                      // Top bar with status and quality.
                      _buildTopBar(state),
                      // Caller information.
                      Expanded(
                        flex: 3,
                        child: _buildCallerInfo(state),
                      ),
                      // Call controls or keypad.
                      Expanded(
                        flex: 4,
                        child: state.callState.isKeypadVisible
                            ? _buildKeypad(state)
                            : _buildCallControls(state),
                      ),
                      // End call button.
                      _buildEndCallSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopBar(ActiveCallInProgress state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Call status indicator.
          Row(
            children: <Widget>[
              ActiveCallPulse(
                color: state.callState.isOnHold
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                state.callState.isOnHold ? 'On Hold' : 'Connected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Call quality indicator.
          CallQualityIndicator(
            quality: state.callState.callQuality,
            showLabel: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCallerInfo(ActiveCallInProgress state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Avatar.
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.blue.shade400,
                Colors.purple.shade400,
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: state.callState.callerAvatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    state.callState.callerAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext _, Object __,
                        StackTrace? ___) {
                      return _buildAvatarPlaceholder(
                        state,
                      );
                    },
                  ),
                )
              : _buildAvatarPlaceholder(state),
        ),
        const SizedBox(height: 24),
        // Caller name.
        Text(
          state.callState.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Caller number.
        Text(
          state.callState.callerNumber,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        // Call duration.
        _buildCallDuration(state),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(ActiveCallInProgress state) {
    final String initials = state.callState.callerName
        .split(' ')
        .take(2)
        .map(
          (String e) => e.isNotEmpty ? e[0].toUpperCase() : '',
        )
        .join();

    return Center(
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCallDuration(ActiveCallInProgress state) {
    final Duration duration = state.callState.callDuration;
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    late final String formatted;
    if (hours > 0) {
      formatted = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      formatted = '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFeatures: <FontFeature>[
            FontFeature.tabularFigures(),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls(ActiveCallInProgress state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Row 1: Mute & Speaker using dedicated audio control widgets.
          AudioControlRow(
            buttonSize: 64,
            spacing: 40,
            onMuteToggled: () {
              context.read<ActiveCallBloc>().add(const ToggleMute());
            },
            onSpeakerToggled: () {
              context
                  .read<ActiveCallBloc>()
                  .add(const ToggleSpeaker());
            },
          ),
          const SizedBox(height: 32),
          // Row 2: Keypad and other controls.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              CallControlButton(
                icon: Icons.dialpad,
                label: 'Keypad',
                onPressed: () {
                  context
                      .read<ActiveCallBloc>()
                      .add(const ToggleKeypad());
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Row 3: Hold, Transfer, Add Call.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              CallControlButton(
                icon: Icons.pause,
                activeIcon: Icons.play_arrow,
                label: state.callState.isOnHold
                    ? 'Resume'
                    : 'Hold',
                isActive: state.callState.isOnHold,
                onPressed: () {
                  context
                      .read<ActiveCallBloc>()
                      .add(const ToggleHold());
                },
              ),
              CallControlButton(
                icon: Icons.call_split,
                label: 'Transfer',
                isEnabled: true,
                onPressed: () {
                  context
                      .read<ActiveCallBloc>()
                      .add(const InitiateTransfer());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Transfer feature coming in Task 45-49',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              CallControlButton(
                icon: Icons.add_call,
                label: 'Add Call',
                isEnabled: false,
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(ActiveCallInProgress state) {
    return DtmfKeypad(
      dtmfInput: state.dtmfInput,
      onKeyPressed: (String digit) {
        context
            .read<ActiveCallBloc>()
            .add(SendDtmfTone(digit));
      },
      onClose: () {
        context
            .read<ActiveCallBloc>()
            .add(const ToggleKeypad());
      },
    );
  }

  Widget _buildEndCallSection() {
    return Column(
      children: <Widget>[
        EndCallButton(
          onPressed: () {
            // End call via ActiveCallBloc.
            context
                .read<ActiveCallBloc>()
                .add(const EndCall());
            // Also notify providers so higher-level and audio state are reset.
            context.read<CallProvider>().endCall();
            context
                .read<AudioControlProvider>()
                .resetForCallEnd();
          },
        ),
        const SizedBox(height: 12),
        Text(
          'End Call',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Best-effort mapping from the BLoC's optional [endReason] string
  /// into a structured [CallEndReason]. Falls back to
  /// [CallEndReason.userHangUp] for generic messages like "User ended call".
  CallEndReason _inferEndReason(String? endReason) {
    if (endReason == null) {
      return CallEndReason.userHangUp;
    }

    final String lower = endReason.toLowerCase();

    if (lower.contains('decline')) {
      return CallEndReason.declined;
    }
    if (lower.contains('remote')) {
      return CallEndReason.remoteHangUp;
    }
    if (lower.contains('no answer')) {
      return CallEndReason.noAnswer;
    }
    if (lower.contains('network')) {
      return CallEndReason.networkError;
    }
    if (lower.contains('fail') || lower.contains('error')) {
      return CallEndReason.connectionFailed;
    }

    return CallEndReason.userHangUp;
  }
}
