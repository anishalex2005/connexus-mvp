import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_control_provider.dart';

/// A button widget for toggling microphone mute during calls.
///
/// Displays a microphone icon that changes based on mute state and
/// shows a loading indicator while the operation is in progress.
class MuteButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Whether to show the label below the button.
  final bool showLabel;

  /// Custom callback after mute toggle (optional).
  final VoidCallback? onToggled;

  const MuteButton({
    super.key,
    this.size = 56,
    this.showLabel = true,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioControlProvider>(
      builder: (
        BuildContext context,
        AudioControlProvider audioProvider,
        Widget? child,
      ) {
        final bool isMuted = audioProvider.isMuted;
        final bool isLoading = audioProvider.isLoading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMuted
                    ? Colors.red.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: isMuted ? Colors.red : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading
                      ? null
                      : () async {
                          await audioProvider.toggleMute();
                          onToggled?.call();
                        },
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: size * 0.4,
                            height: size * 0.4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isMuted ? Colors.red : Colors.white,
                            ),
                          )
                        : Icon(
                            isMuted ? Icons.mic_off : Icons.mic,
                            size: size * 0.45,
                            color: isMuted ? Colors.red : Colors.white,
                          ),
                  ),
                ),
              ),
            ),
            if (showLabel) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                isMuted ? 'Unmute' : 'Mute',
                style: TextStyle(
                  color: isMuted ? Colors.red : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}


