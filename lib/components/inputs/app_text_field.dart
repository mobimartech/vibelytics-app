import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';

/// Standard text field with Vibelytics styling
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: VType.label.copyWith(color: VColors.textSec(context)),
          ),
          VSpace.v2,
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          maxLines: maxLines,
          maxLength: maxLength,
          style: VType.body.copyWith(color: VColors.text(context)),
          cursorColor: VColors.accentPrimary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: VColors.textTer(context))
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: VColors.bgSec(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: VRadii.mdRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: VRadii.mdRadius,
              borderSide: BorderSide(
                color: hasError ? VColors.error : Colors.transparent,
                width: hasError ? 1.5 : 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: VRadii.mdRadius,
              borderSide: BorderSide(
                color: hasError ? VColors.error : VColors.accentPrimary,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: VRadii.mdRadius,
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: VRadii.mdRadius,
              borderSide: const BorderSide(
                color: VColors.error,
                width: 1.5,
              ),
            ),
            counterText: '',
          ),
        ),
        if (hasError) ...[
          VSpace.v1,
          Text(
            errorText!,
            style: VType.caption.copyWith(color: VColors.error),
          ),
        ] else if (helperText != null) ...[
          VSpace.v1,
          Text(
            helperText!,
            style: VType.caption.copyWith(color: VColors.textTer(context)),
          ),
        ],
      ],
    );
  }
}
