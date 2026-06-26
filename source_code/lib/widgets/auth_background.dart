import 'package:flutter/material.dart';

import '../constants.dart';

/// Gradient background with decorative blur circles and scrollable layout.
/// Used as the root widget for authentication screens (Login, Signup, etc.).
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -120,
                  right: -120,
                  child: _BlurCircle(
                    size: 520,
                    color: const Color(0xFF9CECFB),
                    blur: 120,
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -140,
                  child: _BlurCircle(
                    size: 600,
                    color: AppColors.primaryDark,
                    blur: 140,
                    opacity: 0.16,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth < 420
                      ? constraints.maxWidth
                      : AppComponentSizes.glassCardMaxWidth.toDouble();
                  return SizedBox(
                    width: maxWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerPadding,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl,
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;
  final double opacity;

  const _BlurCircle({
    required this.size,
    required this.color,
    required this.blur,
    this.opacity = 0.20,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: blur,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}
