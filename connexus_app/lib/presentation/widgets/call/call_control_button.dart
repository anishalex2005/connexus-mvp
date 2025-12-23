import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A circular button used for call control actions.
/// Supports active/inactive states with visual feedback.
class CallControlButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const CallControlButton({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.isActive = false,
    this.isEnabled = true,
    this.onPressed,
    this.activeColor,
    this.inactiveColor,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveActiveColor =
        activeColor ?? theme.colorScheme.primary;
    final Color effectiveInactiveColor =
        inactiveColor ?? Colors.white.withOpacity(0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Button Container
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    // Haptic feedback on press
                    HapticFeedback.lightImpact();
                    onPressed?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(size / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isActive ? effectiveActiveColor : effectiveInactiveColor,
                border: Border.all(
                  color: isActive
                      ? effectiveActiveColor
                      : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? <BoxShadow>[
                        BoxShadow(
                          color: effectiveActiveColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: isEnabled
                    ? (isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.9))
                    : Colors.white.withOpacity(0.3),
                size: size * 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Label
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isEnabled
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.3),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Specialized end call button with distinct styling.
class EndCallButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isEnabled;

  const EndCallButton({
    super.key,
    this.onPressed,
    this.size = 72.0,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.heavyImpact();
                onPressed?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? Colors.red
                : Colors.red.withOpacity(0.3),
            boxShadow: isEnabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.call_end,
            color: Colors.white,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}


