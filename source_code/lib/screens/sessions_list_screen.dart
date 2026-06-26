import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../providers/services_provider.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/slide_route.dart';
import 'session_active_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'session_create_edit_screen.dart';
import 'settings_screen.dart';

class SessionsListScreen extends ConsumerStatefulWidget {
  const SessionsListScreen({super.key});

  @override
  ConsumerState<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends ConsumerState<SessionsListScreen> {
  final int _selectedNavIndex = 1;
  final Set<String> _expandedSessions = {};

  void _onNavTapped(int index) {
    if (index == _selectedNavIndex) return;
    if (index == 2) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Widget screen = const SizedBox.shrink();
    switch (index) {
      case 0:
        screen = const RemindersScreen();
      case 3:
        screen = const SettingsScreen();
      case 4:
        screen = const ProfileScreen();
    }
    Navigator.pushReplacement(
      context,
      fadeRoute(screen),
    );
  }

  void _toggleExpand(String sessionId) {
    setState(() {
      if (_expandedSessions.contains(sessionId)) {
        _expandedSessions.remove(sessionId);
      } else {
        _expandedSessions.add(sessionId);
      }
    });
  }

  void _startSession(Session session) {
    Navigator.push(
      context,
      fadeRoute(ActiveSessionScreen(session: session)),
    );
  }

  void _editSession(Session session) {
    Navigator.push(
      context,
      fadeRoute(SessionCreationScreen(editSession: session)),
    );
  }

  Future<void> _deleteSession(Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        title: const Text('Delete Session', style: AppTextStyles.headlineSm),
        content: Text('Delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: AppTextStyles.link),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: AppTextStyles.button),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await ref.read(sessionServiceProvider).deleteSession(
        uid: user.uid,
        sessionId: session.id,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

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
                  icon: Icons.timer,
                  title: 'Sessions',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.containerPadding,
                      right: AppSpacing.containerPadding,
                      top: AppSpacing.xl,
                      bottom: 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCreateSessionButton(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionHeader(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSessionsList(user.uid),
                      ],
                    ),
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

  Widget _buildCreateSessionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          fadeRoute(const SessionCreationScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: AppRadius.radiusPill,
          boxShadow: [AppShadows.primaryButton],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: AppIconSizes.xl,
              color: AppColors.onPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Create New Session',
              style: AppTextStyles.button.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Text(
      'Saved Sessions',
      style: AppTextStyles.headlineSm.copyWith(
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildSessionsList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.read(sessionServiceProvider).sessionsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                ref.read(authServiceProvider).readableDataError(snapshot.error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        final sessions = docs
            .map((doc) => Session.fromMap(doc.id, doc.data()))
            .toList();

        return Column(
          children: sessions.map((session) {
            final isExpanded = _expandedSessions.contains(session.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildSessionCard(session, isExpanded),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassWhite,
                boxShadow: [AppShadows.emptyStateCircle],
              ),
              child: Icon(
                Icons.timer_outlined,
                size: 60,
                color: AppColors.primaryAlpha(0.30),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No sessions yet',
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                'Create your first session to start tracking your productive time.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session, bool isExpanded) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.title,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.list_alt_rounded,
                size: AppIconSizes.sm,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${session.taskCount} Tasks',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _toggleExpand(session.id),
                child: Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: AppIconSizes.xl,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _editSession(session),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.edit_rounded,
                    size: AppIconSizes.md,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () => _deleteSession(session),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: AppIconSizes.md,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.glassBorderLight),
                ),
              ),
              child: _buildExpandedItemsList(session),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: AppIconSizes.xs,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      session.totalDurationLabel,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _startSession(session),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: AppRadius.radiusPill,
                    boxShadow: [AppShadows.primaryButton],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: AppIconSizes.xl,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Start',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedItemsList(Session session) {
    final needsScroll = session.items.length > 4;
    return needsScroll
        ? SizedBox(
            height: 150,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: session.items.length,
              itemBuilder: (context, index) {
                return _buildExpandedItem(session.items[index]);
              },
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: session.items.map((item) {
              return _buildExpandedItem(item);
            }).toList(),
          );
  }

  Widget _buildExpandedItem(SessionItem item) {
    final isBreak = item.isBreak;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: isBreak
            ? BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                borderRadius: AppRadius.radiusSm,
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isBreak ? AppColors.secondary : AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                item.name,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isBreak ? AppColors.secondary : AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              item.durationLabel,
              style: AppTextStyles.labelMd.copyWith(
                color: isBreak
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
