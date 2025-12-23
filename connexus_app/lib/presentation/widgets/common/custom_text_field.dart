import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A customized text field widget for the ConnexUS app.
///
/// Provides consistent styling and behavior across the app with
/// support for validation, icons, and various input types.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.autofillHints,
  });

  /// Text editing controller.
  final TextEditingController? controller;

  /// Initial value (used if controller is not provided).
  final String? initialValue;

  /// Label text shown above the field.
  final String? labelText;

  /// Hint text shown when field is empty.
  final String? hintText;

  /// Error text shown below the field.
  final String? errorText;

  /// Icon shown at the start of the field.
  final Widget? prefixIcon;

  /// Icon/widget shown at the end of the field.
  final Widget? suffixIcon;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Whether to show suggestions.
  final bool enableSuggestions;

  /// Keyboard type for this field.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Maximum length of input.
  final int? maxLength;

  /// Maximum lines.
  final int? maxLines;

  /// Minimum lines.
  final int? minLines;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when submit action is triggered.
  final ValueChanged<String>? onSubmitted;

  /// Callback when field is tapped.
  final VoidCallback? onTap;

  /// Validator function.
  final FormFieldValidator<String>? validator;

  /// Focus node for this field.
  final FocusNode? focusNode;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextStyle effectiveInputStyle = isDark
        ? AppTextStyles.inputText.copyWith(color: Colors.white)
        : AppTextStyles.inputText;
    final TextStyle effectiveHintStyle = isDark
        ? AppTextStyles.inputHint.copyWith(color: Colors.white70)
        : AppTextStyles.inputHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (labelText != null) ...<Widget>[
          Text(
            labelText!,
            style: AppTextStyles.labelMedium.copyWith(
              color: errorText != null
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: effectiveHintStyle,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            errorMaxLines: 2,
            counterText: '',
          ),
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          autofillHints: autofillHints,
          style: effectiveInputStyle,
        ),
      ],
    );
  }
}


