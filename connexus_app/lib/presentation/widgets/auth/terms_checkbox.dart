import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/registration_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Checkbox + rich text for accepting terms of service and privacy policy.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildTermsText()),
              ],
            ),
          ),
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              errorText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTermsText() {
    final TextStyle defaultStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      height: 1.4,
    );

    final TextStyle linkStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
      height: 1.4,
    );

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: <InlineSpan>[
          const TextSpan(text: RegistrationStrings.termsPrefix),
          TextSpan(
            text: RegistrationStrings.termsOfService,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onTermsTap,
          ),
          const TextSpan(text: RegistrationStrings.andText),
          TextSpan(
            text: RegistrationStrings.privacyPolicy,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
          ),
        ],
      ),
    );
  }
}


