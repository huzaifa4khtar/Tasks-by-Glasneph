import 'package:flutter/material.dart';

import '../constants.dart';

class OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final Color iconColor;
  final Color labelColor;

  const OptionRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.iconColor = AppColors.primaryDark,
    this.labelColor = AppColors.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppIconSizes.xl, color: iconColor),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: subtitle == null
                      ? Text(label, style: AppTextStyles.headlineSm.copyWith(color: labelColor))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: AppTextStyles.headlineSm.copyWith(color: labelColor)),
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: AppTextStyles.bodyMd,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.xl,
                  color: AppColors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.10),
            ),
          ),
      ],
    );
  }
}
