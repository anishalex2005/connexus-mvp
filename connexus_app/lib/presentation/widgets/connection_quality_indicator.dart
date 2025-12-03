import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connection_state_provider.dart';

/// Widget that displays current WebRTC connection quality.
class ConnectionQualityIndicator extends StatelessWidget {
  final bool showText;
  final bool showDetails;

  const ConnectionQualityIndicator({
    super.key,
    this.showText = true,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionStateProvider>(
      builder: (BuildContext context, ConnectionStateProvider provider, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildSignalBars(provider),
            if (showText) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                provider.qualityText,
                style: TextStyle(
                  color: Color(provider.qualityColor),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (showDetails &&
                provider.connectionQuality.roundTripTime != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                '${provider.connectionQuality.roundTripTime!.toInt()}ms',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSignalBars(ConnectionStateProvider provider) {
    final String quality = provider.connectionQuality.qualityLevel;
    final Color color = Color(provider.qualityColor);

    int activeBars;
    switch (quality) {
      case 'excellent':
        activeBars = 4;
        break;
      case 'good':
        activeBars = 3;
        break;
      case 'fair':
        activeBars = 2;
        break;
      case 'poor':
        activeBars = 1;
        break;
      default:
        activeBars = 0;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List<Widget>.generate(4, (int index) {
        final bool isActive = index < activeBars;
        final double height = 4.0 + (index * 3);

        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

/// Full-screen connection status overlay.
class ConnectionStatusOverlay extends StatelessWidget {
  const ConnectionStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionStateProvider>(
      builder: (BuildContext context, ConnectionStateProvider provider, _) {
        if (!provider.isReconnecting && provider.errorMessage == null) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.black54,
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (provider.isReconnecting) ...<Widget>[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Reconnecting...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please wait while we restore your connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ] else if (provider.errorMessage != null) ...<Widget>[
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.reconnect(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
