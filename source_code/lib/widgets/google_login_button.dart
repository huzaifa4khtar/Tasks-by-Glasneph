import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppComponentSizes.googleButtonHeight,
      width: double.infinity,
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusPill,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.radiusPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFF4285F4),
                        Color(0xFFEA4335),
                        Color(0xFFFBBC05),
                        Color(0xFF34A853),
                      ],
                      stops: [0.0, 0.35, 0.7, 1.0],
                    ).createShader(bounds);
                  },
                  child: const FaIcon(
                    FontAwesomeIcons.google,
                    size: AppIconSizes.sm,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
