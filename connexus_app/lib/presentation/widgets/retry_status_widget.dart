library;

import 'package:flutter/material.dart';

import '../../core/models/retry_state.dart';

/// Widget to display retry status information.
class RetryStatusWidget extends StatelessWidget {
  final RetryState? retryState;
  final VoidCallback? onCancel;
  final VoidCallback? onRetryNow;

  const RetryStatusWidget({
    super.key,
    required this.retryState,
    this.onCancel,
    this.onRetryNow,
  });

  @override
  Widget build(BuildContext context) {
    final RetryState? state = retryState;
    if (state == null || state.status == RetryStatus.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(state.status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildStatusRow(state),
          if (state.status == RetryStatus.waiting) ...<Widget>[
            const SizedBox(height: 12),
            _buildProgressIndicator(state),
            const SizedBox(height: 12),
            _buildCountdownText(state),
          ],
          if (state.status == RetryStatus.attempting) ...<Widget>[
            const SizedBox(height: 12),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
          if (state.isInProgress) ...<Widget>[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(RetryState state) {
    return Row(
      children: <Widget>[
        Icon(
          _getStatusIcon(state.status),
          color: _getIconColor(state.status),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getStatusText(state),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          '${state.currentAttempt}/${state.maxAttempts}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(RetryState state) {
    return LinearProgressIndicator(
      value: state.progress,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        _getProgressColor(state.status),
      ),
    );
  }

  Widget _buildCountdownText(RetryState state) {
    final int seconds = state.nextRetryIn?.inSeconds ?? 0;
    return Text(
      'Retrying in $seconds seconds...',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (onRetryNow != null)
          TextButton(
            onPressed: onRetryNow,
            child: const Text('Retry Now'),
          ),
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Color _getBackgroundColor(RetryStatus status) {
    switch (status) {
      case RetryStatus.succeeded:
        return Colors.green[50]!;
      case RetryStatus.failed:
        return Colors.red[50]!;
      case RetryStatus.cancelled:
        return Colors.grey[100]!;
      case RetryStatus.idle:
      case RetryStatus.waiting:
      case RetryStatus.attempting:
        return Colors.orange[50]!;
    }
  }

  IconData _getStatusIcon(RetryStatus status) {
    switch (status) {
      case RetryStatus.idle:
        return Icons.hourglass_empty;
      case RetryStatus.waiting:
        return Icons.timer;
      case RetryStatus.attempting:
        return Icons.sync;
      case RetryStatus.succeeded:
        return Icons.check_circle;
      case RetryStatus.failed:
        return Icons.error;
      case RetryStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getIconColor(RetryStatus status) {
    switch (status) {
      case RetryStatus.succeeded:
        return Colors.green;
      case RetryStatus.failed:
        return Colors.red;
      case RetryStatus.cancelled:
        return Colors.grey;
      case RetryStatus.idle:
      case RetryStatus.waiting:
      case RetryStatus.attempting:
        return Colors.orange;
    }
  }

  Color _getProgressColor(RetryStatus status) {
    switch (status) {
      case RetryStatus.succeeded:
        return Colors.green;
      case RetryStatus.failed:
        return Colors.red;
      case RetryStatus.idle:
      case RetryStatus.waiting:
      case RetryStatus.attempting:
      case RetryStatus.cancelled:
        return Colors.orange;
    }
  }

  String _getStatusText(RetryState state) {
    switch (state.status) {
      case RetryStatus.idle:
        return 'Ready';
      case RetryStatus.waiting:
        return 'Connection lost. Reconnecting...';
      case RetryStatus.attempting:
        return 'Attempting to connect...';
      case RetryStatus.succeeded:
        return 'Connected successfully';
      case RetryStatus.failed:
        return 'Connection failed';
      case RetryStatus.cancelled:
        return 'Connection cancelled';
    }
  }
}

/// Animated version of retry status for real-time countdown.
class AnimatedRetryStatusWidget extends StatefulWidget {
  final Stream<RetryState?>? retryStateStream;
  final VoidCallback? onCancel;
  final VoidCallback? onRetryNow;

  const AnimatedRetryStatusWidget({
    super.key,
    required this.retryStateStream,
    this.onCancel,
    this.onRetryNow,
  });

  @override
  State<AnimatedRetryStatusWidget> createState() =>
      _AnimatedRetryStatusWidgetState();
}

class _AnimatedRetryStatusWidgetState extends State<AnimatedRetryStatusWidget> {
  RetryState? _currentState;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RetryState?>(
      stream: widget.retryStateStream,
      builder: (BuildContext context, AsyncSnapshot<RetryState?> snapshot) {
        _currentState = snapshot.data;
        return RetryStatusWidget(
          retryState: _currentState,
          onCancel: widget.onCancel,
          onRetryNow: widget.onRetryNow,
        );
      },
    );
  }
}
