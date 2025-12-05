import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/call_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../domain/models/call_model.dart';
import '../../providers/call_provider.dart';
import '../../widgets/call/call_action_button.dart';
import '../../widgets/call/caller_avatar.dart';
import '../../widgets/call/slide_to_answer.dart';

/// Screen displayed when receiving an incoming call.
class IncomingCallScreen extends StatefulWidget {
  final CallModel? call;

  const IncomingCallScreen({
    super.key,
    this.call,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI for full-screen call experience.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: CallColors.backgroundEnd,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Setup fade animation.
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    // Reset system UI.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _handleAnswer(BuildContext context) {
    final callProvider = context.read<CallProvider>();
    callProvider.answerCall();

    // Navigate to active call screen.
    Navigator.of(context).pushReplacementNamed(AppRouter.call);
  }

  void _handleDecline(BuildContext context) {
    final callProvider = context.read<CallProvider>();
    callProvider.declineCall();
    Navigator.of(context).pop();
  }

  void _handleMessage(BuildContext context) {
    // Show quick reply options (will be expanded in later tasks).
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CallColors.backgroundStart,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildQuickReplySheet(context),
    );
  }

  Widget _buildQuickReplySheet(BuildContext context) {
    final quickReplies = <String>[
      "I'll call you back",
      "I'm in a meeting",
      "Can't talk right now",
      "What's up?",
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reply with message',
            style: TextStyle(
              color: CallColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...quickReplies.map(
            (reply) => ListTile(
              title: Text(
                reply,
                style: const TextStyle(color: CallColors.primaryText),
              ),
              onTap: () {
                // TODO: Send SMS and decline call in future tasks.
                Navigator.pop(context);
                _handleDecline(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        final call = widget.call ?? callProvider.currentCall;

        if (call == null) {
          // No call data, close screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CallColors.backgroundStart,
                    CallColors.backgroundEnd,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Caller info section.
                    _buildCallerInfo(call, callProvider.isRinging),

                    const Spacer(flex: 2),

                    // Quick actions.
                    _buildQuickActions(context),

                    const SizedBox(height: 40),

                    // Slide to answer.
                    SlideToAnswer(
                      onAnswer: () => _handleAnswer(context),
                    ),

                    const SizedBox(height: 24),

                    // Decline button.
                    CallActionButton.decline(
                      onPressed: () => _handleDecline(context),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallerInfo(CallModel call, bool isRinging) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar.
        CallerAvatar(
          imageUrl: call.callerPhotoUrl,
          displayName: call.displayName,
          size: 120,
          isRinging: isRinging,
        ),

        const SizedBox(height: 24),

        // Caller name.
        Text(
          call.displayName,
          style: const TextStyle(
            color: CallColors.primaryText,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Phone number (if name is available).
        if (call.callerName != null)
          Text(
            call.formattedNumber,
            style: const TextStyle(
              color: CallColors.secondaryText,
              fontSize: 16,
            ),
          ),

        const SizedBox(height: 16),

        // Call type indicator.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: CallColors.buttonBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.phone_callback,
                color: CallColors.answerGreen,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Incoming Call',
                style: TextStyle(
                  color: CallColors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Remind me button.
        CallActionButton(
          icon: Icons.alarm,
          label: 'Remind me',
          onPressed: () {
            // Placeholder reminder implementation.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder set for 5 minutes')),
            );
          },
        ),

        const SizedBox(width: 48),

        // Message button.
        CallActionButton(
          icon: Icons.message,
          label: 'Message',
          onPressed: () => _handleMessage(context),
        ),
      ],
    );
  }
}
