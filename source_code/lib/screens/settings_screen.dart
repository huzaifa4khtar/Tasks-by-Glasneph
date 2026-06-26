import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/option_row.dart';
import '../widgets/slide_route.dart';
import 'faqs_screen.dart';
import 'sessions_list_screen.dart';
import 'manage_account_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'about_me_screen.dart';
import 'support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int _selectedNavIndex = 3;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  void _onNavTapped(int index) {
    if (index == _selectedNavIndex) return;
    if (index == 2) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Widget screen = const SizedBox.shrink();
    switch (index) {
      case 0: screen = const RemindersScreen();
      case 1: screen = const SessionsListScreen();
      case 4: screen = const ProfileScreen();
    }
    Navigator.pushReplacement(
      context,
      fadeRoute(screen),
    );
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
                const GlassAppBar(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.containerPadding,
                      right: AppSpacing.containerPadding,
                      top: AppSpacing.xl,
                      bottom: 100,
                    ),
                    child: _buildGlassCard(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: BottomNavBar(
              currentIndex: _selectedNavIndex,
              onItemTapped: _onNavTapped,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return GlassCard(
      child: Column(
        children: [
          OptionRow(
            icon: Icons.manage_accounts_rounded,
            label: 'Manage Account',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageAccountScreen(),
              ),
            ),
          ),
          OptionRow(
            icon: Icons.support_agent_rounded,
            label: 'Contact Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SupportScreen(),
              ),
            ),
          ),
          OptionRow(
            icon: Icons.person_rounded,
            label: 'About Me',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AboutMeScreen(),
              ),
            ),
          ),
          OptionRow(
            icon: Icons.quiz_rounded,
            label: 'FAQs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqsScreen()),
            ),
          ),
          OptionRow(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy Policy',
            onTap: () => launchUrl(
              Uri.parse('https://glasneph.github.io/tasks_legal_documentation/privacy_policy.html'),
            ),
          ),
          OptionRow(
            icon: Icons.gavel_rounded,
            label: 'Terms and Conditions',
            onTap: () => launchUrl(
              Uri.parse('https://glasneph.github.io/tasks_legal_documentation/terms_and_conditions.html'),
            ),
          ),
          OptionRow(
            icon: Icons.description_rounded,
            label: 'EULA',
            onTap: () => launchUrl(
              Uri.parse('https://glasneph.github.io/tasks_legal_documentation/end_user_license_agreement.html'),
            ),
            showDivider: false,
          ),
          if (_appVersion.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Version $_appVersion',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
