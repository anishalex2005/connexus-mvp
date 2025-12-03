import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/services/network_monitor_service.dart';
import '../../domain/models/network_state.dart';

/// A widget that displays the current OS-level network status.
///
/// This complements [ConnectionStatusIndicator] (Telnyx registration) and
/// [ConnectionQualityIndicator] (WebRTC quality) by showing WiFi/Cellular/etc.
class NetworkStatusIndicator extends StatelessWidget {
  final bool showLabel;
  final double iconSize;

  const NetworkStatusIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final NetworkMonitorService networkMonitor =
        GetIt.instance<NetworkMonitorService>();

    return StreamBuilder<NetworkState>(
      stream: networkMonitor.networkStateStream,
      initialData: networkMonitor.currentState,
      builder: (BuildContext context, AsyncSnapshot<NetworkState> snapshot) {
        final NetworkState state = snapshot.data ?? NetworkState.unknown();

        return _NetworkStatusContent(
          state: state,
          showLabel: showLabel,
          iconSize: iconSize,
        );
      },
    );
  }
}

class _NetworkStatusContent extends StatelessWidget {
  final NetworkState state;
  final bool showLabel;
  final double iconSize;

  const _NetworkStatusContent({
    required this.state,
    required this.showLabel,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = _getStatusDetails();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: iconSize,
          color: color,
        ),
        if (showLabel) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            label,
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

  (IconData, Color, String) _getStatusDetails() {
    if (!state.isConnected) {
      return (Icons.signal_wifi_off, Colors.red, 'No Connection');
    }

    switch (state.status) {
      case NetworkStatus.wifi:
        return _getWifiDetails();
      case NetworkStatus.cellular:
        return _getCellularDetails();
      case NetworkStatus.ethernet:
        return (Icons.settings_ethernet, Colors.green, 'Ethernet');
      case NetworkStatus.disconnected:
        return (Icons.signal_wifi_off, Colors.red, 'Disconnected');
      case NetworkStatus.unknown:
        return (Icons.signal_wifi_statusbar_null, Colors.grey, 'Unknown');
    }
  }

  (IconData, Color, String) _getWifiDetails() {
    switch (state.quality) {
      case NetworkQuality.excellent:
        return (Icons.wifi, Colors.green, 'WiFi - Excellent');
      case NetworkQuality.good:
        return (Icons.wifi, Colors.green, 'WiFi');
      case NetworkQuality.poor:
        return (Icons.wifi_2_bar, Colors.orange, 'WiFi - Poor');
      case NetworkQuality.unstable:
        return (Icons.wifi_1_bar, Colors.red, 'WiFi - Unstable');
      case NetworkQuality.unknown:
        return (Icons.wifi, Colors.blue, 'WiFi');
    }
  }

  (IconData, Color, String) _getCellularDetails() {
    switch (state.quality) {
      case NetworkQuality.excellent:
        return (Icons.signal_cellular_4_bar, Colors.green, 'Cellular');
      case NetworkQuality.good:
        return (Icons.signal_cellular_4_bar, Colors.green, 'Cellular');
      case NetworkQuality.poor:
        return (
          Icons.signal_cellular_alt_2_bar,
          Colors.orange,
          'Cellular - Poor',
        );
      case NetworkQuality.unstable:
        return (
          Icons.signal_cellular_alt_1_bar,
          Colors.red,
          'Cellular - Weak',
        );
      case NetworkQuality.unknown:
        return (Icons.signal_cellular_4_bar, Colors.blue, 'Cellular');
    }
  }
}

/// A banner widget for showing network issues during calls.
class NetworkWarningBanner extends StatelessWidget {
  const NetworkWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final NetworkMonitorService networkMonitor =
        GetIt.instance<NetworkMonitorService>();

    return StreamBuilder<NetworkState>(
      stream: networkMonitor.networkStateStream,
      initialData: networkMonitor.currentState,
      builder: (BuildContext context, AsyncSnapshot<NetworkState> snapshot) {
        final NetworkState state = snapshot.data ?? NetworkState.unknown();

        // Only show banner if there's an issue.
        if (state.isConnected &&
            state.quality != NetworkQuality.poor &&
            state.quality != NetworkQuality.unstable) {
          return const SizedBox.shrink();
        }

        return _WarningBannerContent(state: state);
      },
    );
  }
}

class _WarningBannerContent extends StatelessWidget {
  final NetworkState state;

  const _WarningBannerContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final (String message, Color color, IconData icon) = _getBannerDetails();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getBannerDetails() {
    if (!state.isConnected) {
      return (
        'No network connection. Call may be interrupted.',
        Colors.red,
        Icons.signal_wifi_off,
      );
    }

    if (state.quality == NetworkQuality.unstable) {
      return (
        'Unstable connection. Expect call quality issues.',
        Colors.orange,
        Icons.warning_amber,
      );
    }

    if (state.quality == NetworkQuality.poor) {
      return (
        'Poor network quality. Voice may be choppy.',
        Colors.orange,
        Icons.signal_wifi_bad,
      );
    }

    return ('Network issue detected', Colors.orange, Icons.info_outline);
  }
}
