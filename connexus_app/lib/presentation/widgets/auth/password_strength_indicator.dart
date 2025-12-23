import 'package:flutter/material.dart';

import '../../../core/constants/registration_strings.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A widget that displays password strength visually with a progress bar
/// and individual requirement checkmarks.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.validationResult,
    this.showRequirements = true,
  });

  /// The current password validation state.
  final PasswordValidationResult validationResult;

  /// Whether to show the individual requirement checklist.
  final bool showRequirements;

  @override
  Widget build(BuildContext context) {
    // Do not render anything for an empty password.
    if (validationResult.strength == PasswordStrength.empty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStrengthBar(),
        const SizedBox(height: 8),
        _buildStrengthLabel(),
        if (showRequirements) ...<Widget>[
          const SizedBox(height: 12),
          _buildRequirementsList(),
        ],
      ],
    );
  }

  Widget _buildStrengthBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _strengthProgress,
        backgroundColor: AppColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
        minHeight: 6,
      ),
    );
  }

  Widget _buildStrengthLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Password strength:',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          _strengthLabel,
          style: AppTextStyles.bodySmall.copyWith(
            color: _strengthColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          RegistrationStrings.passwordRequirements,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _RequirementItem(
          label: RegistrationStrings.requirementLength,
          isMet: validationResult.hasMinLength,
        ),
        _RequirementItem(
          label: RegistrationStrings.requirementUppercase,
          isMet: validationResult.hasUppercase,
        ),
        _RequirementItem(
          label: RegistrationStrings.requirementLowercase,
          isMet: validationResult.hasLowercase,
        ),
        _RequirementItem(
          label: RegistrationStrings.requirementNumber,
          isMet: validationResult.hasNumber,
        ),
        _RequirementItem(
          label: RegistrationStrings.requirementSpecial,
          isMet: validationResult.hasSpecialChar,
        ),
      ],
    );
  }

  double get _strengthProgress {
    switch (validationResult.strength) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1;
    }
  }

  Color get _strengthColor {
    switch (validationResult.strength) {
      case PasswordStrength.empty:
        return AppColors.textTertiary;
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return AppColors.success;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String get _strengthLabel {
    switch (validationResult.strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return RegistrationStrings.strengthWeak;
      case PasswordStrength.fair:
        return RegistrationStrings.strengthFair;
      case PasswordStrength.good:
        return RegistrationStrings.strengthGood;
      case PasswordStrength.strong:
        return RegistrationStrings.strengthStrong;
    }
  }
}

/// Individual requirement item with checkmark/cross.
class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.label,
    required this.isMet,
  });

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isMet ? AppColors.textPrimary : AppColors.textSecondary,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}


