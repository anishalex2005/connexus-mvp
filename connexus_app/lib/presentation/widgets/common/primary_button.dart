import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Primary action button for the ConnexUS app.
///
/// A full-width button with loading state support.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = 56,
  });

  /// Button text.
  final String text;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show loading indicator.
  final bool isLoading;

  /// Whether the button is enabled.
  final bool isEnabled;

  /// Optional icon to show before text.
  final IconData? icon;

  /// Button width (default is full width).
  final double? width;

  /// Button height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isActive = isEnabled && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isActive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.5),
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          disabledForegroundColor: AppColors.textOnPrimary.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textOnPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


