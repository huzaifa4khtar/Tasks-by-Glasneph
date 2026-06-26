import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

class AboutMeScreen extends StatelessWidget {
  const AboutMeScreen({super.key});

  static final Uri _instagramHuzaifa = Uri.parse(
    'https://www.instagram.com/huzaifa4khtar/',
  );
  static final Uri _instagramGlasneph = Uri.parse(
    'https://www.instagram.com/glasneph/',
  );

  Future<void> _launchUrl(
    Uri url, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    try {
      await launchUrl(url, mode: mode);
    } catch (_) {}
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerPadding,
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey there!',
                          style: AppTextStyles.bodyHandwritten.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Thanks so much for using my app, it genuinely means a lot.',
                          style: AppTextStyles.bodyHandwritten,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "To Keep it Short, My name is Huzaifa. I'm a software developer from Pakistan, and I designed and developed this app entirely on my own.",
                          style: AppTextStyles.bodyHandwritten,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "If you like my work, connect with me through the companys socials or my personal instagram account:",
                          style: AppTextStyles.bodyHandwritten,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSocialRow(
                          icon: Image.asset(
                            'assets/Icons/instagram_logo.png',
                            width: 20,
                            height: 20,
                          ),
                          label: '@huzaifa4khtar',
                          onTap: () => _launchUrl(_instagramHuzaifa),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _buildSocialRow(
                          icon: Image.asset(
                            'assets/Icons/instagram_logo.png',
                            width: 20,
                            height: 20,
                          ),
                          label: '@glasneph',
                          onTap: () => _launchUrl(_instagramGlasneph),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Thanks again for being here. It really does mean something :) .',
                          style: AppTextStyles.bodyHandwritten,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '~ Huzaifa',
                            style: AppTextStyles.bodyHandwritten.copyWith(
                              fontWeight: FontWeight.w600,
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

  Widget _buildSocialRow({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodyHandwritten.copyWith(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryDark,
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
        border: Border(bottom: BorderSide(color: AppColors.glassBorderLight)),
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
              Icons.person_rounded,
              size: AppIconSizes.header,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Text('About Me', style: AppTextStyles.headlineMd),
          ],
        ),
      ),
    );
  }
}
