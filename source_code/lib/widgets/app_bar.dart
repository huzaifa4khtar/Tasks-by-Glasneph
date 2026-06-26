import 'package:flutter/material.dart';

import '../constants.dart';

class GlassAppBar extends StatelessWidget {
  final IconData icon;
  final String title;

  const GlassAppBar({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorderLight),
        ),
      ),
      child: SizedBox(
        height: AppComponentSizes.headerHeight,
        child: Row(
          children: [
            Icon(icon, size: AppIconSizes.header, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
