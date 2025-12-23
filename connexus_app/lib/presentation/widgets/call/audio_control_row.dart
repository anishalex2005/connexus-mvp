import 'package:flutter/material.dart';

import 'mute_button.dart';
import 'speaker_button.dart';

/// A horizontal row containing both mute and speaker controls.
///
/// This widget provides a consistent layout for audio controls
/// on the active call screen.
class AudioControlRow extends StatelessWidget {
  /// Size of each button.
  final double buttonSize;

  /// Spacing between buttons.
  final double spacing;

  /// Whether to show labels under buttons.
  final bool showLabels;

  /// Optional callback invoked after mute is toggled.
  final VoidCallback? onMuteToggled;

  /// Optional callback invoked after speaker is toggled.
  final VoidCallback? onSpeakerToggled;

  const AudioControlRow({
    super.key,
    this.buttonSize = 56,
    this.spacing = 32,
    this.showLabels = true,
    this.onMuteToggled,
    this.onSpeakerToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        MuteButton(
          size: buttonSize,
          showLabel: showLabels,
          onToggled: onMuteToggled,
        ),
        SizedBox(width: spacing),
        SpeakerButton(
          size: buttonSize,
          showLabel: showLabels,
          onToggled: onSpeakerToggled,
        ),
      ],
    );
  }
}


