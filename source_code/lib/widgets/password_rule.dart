import 'package:flutter/material.dart';

import '../constants.dart';

class PasswordRule extends StatelessWidget {
  final String text;
  final bool isMet;

  const PasswordRule({super.key, required this.text, required this.isMet});

  @override
  Widget build(BuildContext context) {
    final color = isMet ? AppColors.success : AppColors.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: AppIconSizes.sm,
          color: color,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
