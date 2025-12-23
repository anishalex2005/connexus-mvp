import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/call_constants.dart';
import '../../../domain/models/call_model.dart';

/// Screen shown after a call ends with summary information.
class CallEndedScreen extends StatefulWidget {
  final CallModel? call;
  final CallEndReason endReason;
  final Duration duration;
  final VoidCallback? onDismiss;

  const CallEndedScreen({
    super.key,
    required this.endReason,
    required this.duration,
    this.call,
    this.onDismiss,
  });

  @override
  State<CallEndedScreen> createState() => _CallEndedScreenState();
}

class _CallEndedScreenState extends State<CallEndedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Auto-dismiss after a short delay if no action taken.
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  String get _formattedDuration {
    final int totalSeconds = widget.duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final CallModel? call = widget.call;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(flex: 2),
                  _buildIcon(theme),
                  const SizedBox(height: 24),
                  Text(
                    widget.endReason.displayText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (call != null)
                    Text(
                      call.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color
                            ?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  _buildDuration(theme),
                  const SizedBox(height: 16),
                  if (call != null) _buildDetails(call, theme),
                  const Spacer(flex: 2),
                  TextButton(
                    onPressed: _handleDismiss,
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color
                            ?.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final bool isError = widget.endReason == CallEndReason.networkError ||
        widget.endReason == CallEndReason.connectionFailed;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isError
            ? Colors.red.withOpacity(0.12)
            : Colors.grey.withOpacity(0.12),
      ),
      child: Icon(
        Icons.call_end,
        size: 44,
        color: isError ? Colors.red : theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDuration(ThemeData theme) {
    return Column(
      children: <Widget>[
        Text(
          'Duration',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedDuration,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(CallModel call, ThemeData theme) {
    final DateFormat timeFormat = DateFormat('h:mm a');
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    final String timeRange = call.endTime != null
        ? '${timeFormat.format(call.startTime)} - '
            '${timeFormat.format(call.endTime!)}'
        : timeFormat.format(call.startTime);

    final String directionLabel =
        call.direction == CallDirection.incoming ? 'Incoming call' : 'Outgoing call';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: <Widget>[
          _buildDetailRow(
            theme: theme,
            icon: Icons.access_time,
            label: 'Time',
            value: timeRange,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            theme: theme,
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFormat.format(call.startTime),
          ),
          const Divider(height: 16),
          _buildDetailRow(
            theme: theme,
            icon: call.direction == CallDirection.incoming
                ? Icons.call_received
                : Icons.call_made,
            label: 'Type',
            value: directionLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 20,
          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}


