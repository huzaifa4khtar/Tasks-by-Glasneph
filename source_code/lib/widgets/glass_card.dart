import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final BorderRadiusGeometry? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.radiusXxl;
    return Container(
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.glassWhite,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [AppShadows.glassCard],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
