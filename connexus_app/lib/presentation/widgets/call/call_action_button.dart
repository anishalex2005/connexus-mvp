import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/call_colors.dart';

/// Circular action button for call screens.
class CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;
  final double size;
  final bool isLarge;

  const CallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor = CallColors.buttonBackground,
    this.iconColor = CallColors.primaryText,
    this.size = 64,
    this.isLarge = false,
  });

  /// Factory for answer button.
  factory CallActionButton.answer({
    required VoidCallback onPressed,
  }) {
    return CallActionButton(
      icon: Icons.call,
      label: 'Answer',
      backgroundColor: CallColors.answerGreen,
      iconColor: Colors.white,
      onPressed: onPressed,
      isLarge: true,
    );
  }

  /// Factory for decline button.
  factory CallActionButton.decline({
    required VoidCallback onPressed,
  }) {
    return CallActionButton(
      icon: Icons.call_end,
      label: 'Decline',
      backgroundColor: CallColors.declineRed,
      iconColor: Colors.white,
      onPressed: onPressed,
      isLarge: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = isLarge ? size * 1.2 : size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onPressed();
            },
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: buttonSize * 0.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: CallColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
