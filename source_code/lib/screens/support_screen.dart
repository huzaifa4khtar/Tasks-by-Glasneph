import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static final Uri _emailUri = Uri.parse('mailto:glasneph@gmail.com');

  Future<void> _openEmail(BuildContext context) async {
    try {
      final canOpen = await canLaunchUrl(_emailUri);
      if (!canOpen) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email app found on this device.')),
          );
        }
        return;
      }
      await launchUrl(_emailUri);
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.containerPadding,
                      right: AppSpacing.containerPadding,
                      top: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 64,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Need help or have a suggestion?',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMd.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'To report any issue with the app or to suggest a feature, feel free to email me at:',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        GestureDetector(
                          onTap: () => _openEmail(context),
                          child: Text(
                            'glasneph@gmail.com',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_rounded,
                size: AppIconSizes.header,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.support_agent_rounded,
              size: AppIconSizes.header,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Contact Support',
              style: AppTextStyles.headlineMd,
            ),
          ],
        ),
      ),
    );
  }
}
