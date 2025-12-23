import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_control_provider.dart';
import '../../../domain/models/audio_output_type.dart';

/// A button widget for toggling speaker output during calls.
///
/// Displays a speaker/Bluetooth/earpiece icon that changes based on
/// the current active output and connection state. Long press opens
/// an audio output selector when multiple outputs are available.
class SpeakerButton extends StatelessWidget {
  /// Size of the button.
  final double size;

  /// Whether to show the label below the button.
  final bool showLabel;

  /// Custom callback after speaker toggle (optional).
  final VoidCallback? onToggled;

  const SpeakerButton({
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
        final bool isSpeakerOn = audioProvider.isSpeakerOn;
        final bool isBluetoothConnected = audioProvider.isBluetoothConnected;
        final bool isLoading = audioProvider.isLoading;
        final bool hasMultipleOutputs = audioProvider.hasMultipleOutputs;

        // Determine icon and label based on current output.
        IconData icon;
        String label;
        Color activeColor;

        if (isBluetoothConnected &&
            audioProvider.currentOutput == AudioOutputType.bluetooth) {
          icon = Icons.bluetooth_audio;
          label = audioProvider.bluetoothDeviceName ?? 'Bluetooth';
          activeColor = Colors.blue;
        } else if (isSpeakerOn) {
          icon = Icons.volume_up;
          label = 'Speaker';
          activeColor = Colors.green;
        } else {
          icon = Icons.phone_in_talk;
          label = 'Earpiece';
          activeColor = Colors.white;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onLongPress: hasMultipleOutputs
                  ? () => _showAudioOutputSelector(
                        context,
                        audioProvider,
                      )
                  : null,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSpeakerOn
                      ? Colors.green.withOpacity(0.2)
                      : isBluetoothConnected
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: isSpeakerOn
                        ? Colors.green
                        : isBluetoothConnected
                            ? Colors.blue
                            : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading
                        ? null
                        : () async {
                            await audioProvider.toggleSpeaker();
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
                                color: activeColor,
                              ),
                            )
                          : Icon(
                              icon,
                              size: size * 0.45,
                              color: activeColor,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (showLabel) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAudioOutputSelector(
    BuildContext context,
    AudioControlProvider audioProvider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) =>
          AudioOutputSelector(audioProvider: audioProvider),
    );
  }
}

/// Bottom sheet for selecting audio output device.
class AudioOutputSelector extends StatelessWidget {
  final AudioControlProvider audioProvider;

  const AudioOutputSelector({
    super.key,
    required this.audioProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Audio Output',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          ...audioProvider.availableOutputs.map(
            (AudioOutputType output) {
              final bool isSelected =
                  audioProvider.currentOutput == output;

              String title;
              IconData icon;

              switch (output) {
                case AudioOutputType.earpiece:
                  title = 'Phone';
                  icon = Icons.phone_in_talk;
                  break;
                case AudioOutputType.speaker:
                  title = 'Speaker';
                  icon = Icons.volume_up;
                  break;
                case AudioOutputType.bluetooth:
                  title =
                      audioProvider.bluetoothDeviceName ?? 'Bluetooth';
                  icon = Icons.bluetooth_audio;
                  break;
                case AudioOutputType.wiredHeadset:
                  title = 'Headphones';
                  icon = Icons.headset;
                  break;
              }

              return ListTile(
                leading: Icon(
                  icon,
                  color: isSelected ? Colors.green : Colors.white,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.green : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  audioProvider.setAudioOutput(output);
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


