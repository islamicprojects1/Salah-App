import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

/// Unified text field with full feature support
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextStyle? textStyle;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.prefix,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textStyle,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  Widget? get _suffixIcon {
    if (widget.suffix != null) return widget.suffix;
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return null;
  }

  bool get _effectiveObscureText =>
      widget.suffix != null ? widget.obscureText : _obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _effectiveObscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLines: _effectiveObscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      style: widget.textStyle ?? AppFonts.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        counterText: '',
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary)
            : widget.prefix,
        suffixIcon: _suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingMD,
        ),
      ),
    );
  }
}

// ── PRESET FIELDS ────────────────────────────────────────────────────────────

/// Email field with built-in validation
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const EmailTextField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'email_label'.tr,
      hint: 'example@email.com',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return 'enter_email'.tr;
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) return 'invalid_email'.tr;
            return null;
          },
    );
  }
}

/// Password field with visibility toggle and validation
class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.obscureText = true,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'password_label'.tr,
      obscureText: obscureText,
      prefixIcon: Icons.lock_outlined,
      suffix: suffixIcon,
      textInputAction: textInputAction ?? TextInputAction.done,
      onChanged: onChanged,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return 'enter_password'.tr;
            if (value.length < 6) return 'password_min_length'.tr;
            return null;
          },
    );
  }
}

/// Name field (capitalizes words)
class NameTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const NameTextField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'name_label'.tr,
      prefixIcon: Icons.person_outline,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) return 'enter_name'.tr;
            return null;
          },
    );
  }
}

/// Search field (no validation, clear button)
class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint ?? 'search'.tr,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      suffix: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}
