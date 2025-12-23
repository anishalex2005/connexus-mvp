import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../common/custom_text_field.dart';

/// A customized text field for authentication screens, built on top of
/// the shared [CustomTextField] to keep styling consistent.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enablePasswordToggle;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: widget.controller,
          labelText: null,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: _buildSuffixIcon(),
          obscureText:
              widget.enablePasswordToggle ? _obscureText : widget.obscureText,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          focusNode: widget.focusNode,
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (!widget.enablePasswordToggle) {
      return null;
    }

    return IconButton(
      icon: Icon(
        _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textTertiary,
      ),
      onPressed: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
    );
  }
}

/// Email-specific auth text field with sensible defaults.
class EmailTextField extends StatelessWidget {
  const EmailTextField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      label: 'Email Address',
      hint: 'you@example.com',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: AppColors.textTertiary,
      ),
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      enabled: enabled,
    );
  }
}

/// Password text field with visibility toggle.
class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      label: label,
      hint: hint,
      obscureText: true,
      enablePasswordToggle: true,
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: AppColors.textTertiary,
      ),
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      enabled: enabled,
    );
  }
}


