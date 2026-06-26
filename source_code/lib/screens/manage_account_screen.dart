import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/option_row.dart';
import 'delete_account_screen.dart';
import 'update_email_screen.dart';
import 'update_password_screen.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  String _lastKnownEmail =
      FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

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
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              initialData: FirebaseAuth.instance.currentUser,
              builder: (context, snapshot) {
                final liveEmail = snapshot.data?.email;
                if (liveEmail != null && liveEmail.trim().isNotEmpty) {
                  _lastKnownEmail = liveEmail;
                }
                final userEmail = _lastKnownEmail;

                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.containerPadding,
                          right: AppSpacing.containerPadding,
                          top: AppSpacing.xl,
                          bottom: 100,
                        ),
                        child: _buildGlassCard(userEmail),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.manage_accounts_rounded,
              size: AppIconSizes.header,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Manage Account',
              style: AppTextStyles.headlineMd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(String userEmail) {
    return GlassCard(
      child: Column(
        children: [
          OptionRow(
            icon: Icons.email_rounded,
            label: 'Update Email',
            subtitle: userEmail,
            onTap: () async {
              final sentTo = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UpdateEmailScreen(currentEmail: userEmail),
                ),
              );
              if (!mounted) return;
              if (sentTo != null && sentTo.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email sent to ${sentTo.trim()}')),
                );
              }
            },
          ),
          OptionRow(
            icon: Icons.lock_rounded,
            label: 'Update Password',
            subtitle: 'Change your password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    UpdatePasswordScreen(userEmail: userEmail),
              ),
            ),
          ),
          OptionRow(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Account',
            onTap: () {
              final email = FirebaseAuth.instance.currentUser?.email ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeleteAccountScreen(userEmail: email),
                ),
              );
            },
            showDivider: false,
            iconColor: AppColors.error,
            labelColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}
