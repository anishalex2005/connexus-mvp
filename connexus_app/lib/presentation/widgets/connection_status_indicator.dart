import 'package:flutter/material.dart';

import '../../domain/telephony/telnyx_connection_state.dart';
import '../../data/services/telnyx_service.dart';
import '../../injection.dart';

/// Widget that displays the current Telnyx connection status.
class ConnectionStatusIndicator extends StatelessWidget {
  final bool showText;
  final double iconSize;

  const ConnectionStatusIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final telnyxService = getIt<TelnyxService>();

    return StreamBuilder<TelnyxConnectionState>(
      stream: telnyxService.connectionStateStream,
      initialData: telnyxService.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? TelnyxConnectionState.disconnected;
        return _buildIndicator(context, state);
      },
    );
  }

  Widget _buildIndicator(BuildContext context, TelnyxConnectionState state) {
    final color = _getColorForState(state);
    final icon = _getIconForState(state);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.isConnecting)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            state.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getColorForState(TelnyxConnectionState state) {
    switch (state) {
      case TelnyxConnectionState.registered:
        return Colors.green;
      case TelnyxConnectionState.connecting:
      case TelnyxConnectionState.reconnecting:
        return Colors.orange;
      case TelnyxConnectionState.failed:
        return Colors.red;
      case TelnyxConnectionState.disconnected:
      case TelnyxConnectionState.loggedOut:
        return Colors.grey;
    }
  }

  IconData _getIconForState(TelnyxConnectionState state) {
    switch (state) {
      case TelnyxConnectionState.registered:
        return Icons.check_circle;
      case TelnyxConnectionState.connecting:
      case TelnyxConnectionState.reconnecting:
        return Icons.sync;
      case TelnyxConnectionState.failed:
        return Icons.error;
      case TelnyxConnectionState.disconnected:
      case TelnyxConnectionState.loggedOut:
        return Icons.cloud_off;
    }
  }
}

/// Full connection status card with retry button.
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final telnyxService = getIt<TelnyxService>();

    return StreamBuilder<TelnyxConnectionState>(
      stream: telnyxService.connectionStateStream,
      initialData: telnyxService.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? TelnyxConnectionState.disconnected;

        if (state == TelnyxConnectionState.registered) {
          return const SizedBox.shrink();
        }

        return Card(
          color: _getBackgroundColor(state),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ConnectionStatusIndicator(showText: false, iconSize: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getDescriptionForState(state),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state == TelnyxConnectionState.failed ||
                    state == TelnyxConnectionState.disconnected)
                  TextButton(
                    onPressed: () =>
                        telnyxService.connectWithStoredCredentials(),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(TelnyxConnectionState state) {
    switch (state) {
      case TelnyxConnectionState.failed:
        return Colors.red[50]!;
      case TelnyxConnectionState.connecting:
      case TelnyxConnectionState.reconnecting:
        return Colors.orange[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _getDescriptionForState(TelnyxConnectionState state) {
    switch (state) {
      case TelnyxConnectionState.connecting:
        return 'Establishing connection to telephony server...';
      case TelnyxConnectionState.reconnecting:
        return 'Connection lost. Attempting to reconnect...';
      case TelnyxConnectionState.failed:
        return 'Unable to connect. Please check your internet connection.';
      case TelnyxConnectionState.disconnected:
        return 'Not connected to telephony server.';
      case TelnyxConnectionState.loggedOut:
        return 'Logged out from telephony service.';
      default:
        return '';
    }
  }
}
