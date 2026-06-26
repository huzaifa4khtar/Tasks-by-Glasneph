import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/slide_route.dart';
import 'sessions_list_screen.dart';
import 'login_screen.dart';
import 'my_lists_screen.dart';
import 'profile_edit_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = ref.read(authServiceProvider);

    if (user == null) {
      return const LoginScreen();
    }

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
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: authService.userProfileStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  if (FirebaseAuth.instance.currentUser == null) {
                    return const SizedBox.shrink();
                  }
                  return Center(
                    child: Text(
                      authService.readableDataError(snapshot.error),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                final data = snapshot.data?.data() ?? <String, dynamic>{};
                final name = (data['name'] as String?)?.trim().isNotEmpty == true
                    ? (data['name'] as String).trim()
                    : (user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!.trim()
                        : 'User');
                final email =
                    (data['email'] as String?)?.trim().isNotEmpty == true
                        ? (data['email'] as String).trim()
                        : (user.email ?? 'Not set');
                final createdAt = data['createdAt'] as Timestamp?;
                final memberSince = createdAt != null
                    ? _formatMemberSince(createdAt.toDate())
                    : 'Not available';
                final avatar = data['avatar'] as String?;
                final sessionsCompleted = (data['sessionsCompleted'] as num?)?.toInt() ?? 0;

                return Column(
                  children: [
                    const GlassAppBar(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.containerPadding,
                          right: AppSpacing.containerPadding,
                          top: AppSpacing.sm,
                          bottom: 100,
                        ),
                        child: Column(
                          children: [
                            _buildProfileHeader(name, avatar),
                            const SizedBox(height: AppSpacing.lg),
                            _buildInfoCard(email, memberSince),
                            const SizedBox(height: AppSpacing.md),
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: ref.read(taskServiceProvider).tasksStream(user.uid),
                              builder: (context, taskSnapshot) {
                                final docs = taskSnapshot.data?.docs ?? [];
                                final totalCount = docs.length;
                                final doneCount = docs.where((d) => (d.data()['isDone'] as bool?) == true).length;
                                return _buildStatsGrid(doneCount: doneCount, totalCount: totalCount, sessionsCompleted: sessionsCompleted);
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildMyLists(),
                            const SizedBox(height: AppSpacing.sm),
                            _buildLogOut(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
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

  final int _selectedNavIndex = 4;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatMemberSince(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
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
      case 3: screen = const SettingsScreen();
      case 4: screen = const ProfileScreen();
    }
    Navigator.pushReplacement(
      context,
      fadeRoute(screen),
    );
  }

  Widget _buildProfileHeader(String name, String? avatar) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    color: AppColors.primaryAlpha(0.18),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage(
                  avatar?.isNotEmpty == true
                      ? avatar!
                      : 'assets/user_profile_default_image.jpg',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: AppSpacing.md,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
            child: Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: AppIconSizes.lg,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Edit Profile',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSizes.lg,
                  color: AppColors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String email, String memberSince) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            label: 'Email',
            value: email,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.10),
            ),
          ),
          _buildInfoRow(
            label: 'Member Since',
            value: memberSince,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.primaryDark.withValues(alpha: 0.60),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid({required int doneCount, required int totalCount, required int sessionsCompleted}) {
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          Expanded(child: _buildStatCard(
            icon: const Icon(Icons.check_circle_rounded, size: 24, color: AppColors.primaryDark),
            value: '$doneCount/$totalCount',
            label: 'Tasks Done',
          )),
          const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildStatCard(
          icon: const Icon(Icons.timer, size: 24, color: AppColors.primaryDark),
          value: '$sessionsCompleted',
          label: 'Sessions Completed',
        )),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required Widget icon,
    required String value,
    required String label,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLists() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.md,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyListsScreen()),
          );
        },
        child: Row(
          children: [
            Icon(
              Icons.list_alt_rounded,
              size: AppIconSizes.lg,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'My Lists',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIconSizes.lg,
              color: AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogOut() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.md,
      ),
      child: GestureDetector(
        onTap: _signOut,
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              size: AppIconSizes.lg,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Log Out',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIconSizes.lg,
              color: AppColors.error.withValues(alpha: 0.40),
            ),
          ],
        ),
      ),
    );
  }
}
