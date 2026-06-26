import 'package:flutter/material.dart';

import '../constants.dart';

class GlassAuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget? leadingIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final bool hasLeftInsetGlow;

  final VoidCallback? onToggleObscure;

  const GlassAuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.leadingIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.hasLeftInsetGlow = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassTextFieldInternal(
      controller: controller,
      label: label,
      hint: hint,
      leadingIcon: leadingIcon,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      hasLeftInsetGlow: hasLeftInsetGlow,
      onToggleObscure: onToggleObscure,
    );
  }
}

class _GlassTextFieldInternal extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget? leadingIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final bool hasLeftInsetGlow;
  final VoidCallback? onToggleObscure;

  const _GlassTextFieldInternal({
    required this.controller,
    required this.label,
    required this.hint,
    required this.leadingIcon,
    required this.keyboardType,
    required this.obscureText,
    required this.enabled,
    required this.validator,
    required this.hasLeftInsetGlow,
    required this.onToggleObscure,
  });

  @override
  State<_GlassTextFieldInternal> createState() =>
      _GlassTextFieldInternalState();
}

class _GlassTextFieldInternalState extends State<_GlassTextFieldInternal> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final showLabel = widget.label.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(top: showLabel ? 8 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Text(
              widget.label,
              style: AppTextStyles.labelMd,
            ),
          if (showLabel) const SizedBox(height: AppSpacing.xs),
          TextFormField(
            focusNode: _focusNode,
            controller: widget.controller,
            enabled: widget.enabled,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            cursorColor: AppColors.primaryDark,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 1.2,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: AppSpacing.containerPadding,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusPill,
                borderSide: BorderSide(
                  color: isFocused ? AppColors.primaryDark : AppColors.outlineVariant,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusPill,
                borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusPill,
                borderSide: const BorderSide(
                  color: AppColors.primaryDark,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusPill,
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusPill,
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              prefixIcon: widget.leadingIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 6, right: 10),
                      child: widget.leadingIcon,
                    ),
              suffixIcon: widget.onToggleObscure == null
                  ? null
                  : IconButton(
                      onPressed: widget.onToggleObscure,
                      icon: Icon(
                        widget.obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
