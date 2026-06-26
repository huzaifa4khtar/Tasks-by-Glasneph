import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/task_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/slide_route.dart';
import 'sessions_list_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final int _selectedNavIndex = 0;
  final TaskService _taskService = TaskService();
  void _onNavTapped(int index) {
    if (index == _selectedNavIndex) return;
    if (index == 2) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Widget screen = const SizedBox.shrink();
    switch (index) {
      case 1: screen = const SessionsListScreen();
      case 3: screen = const SettingsScreen();
      case 4: screen = const ProfileScreen();
    }
    Navigator.pushReplacement(
      context,
      fadeRoute(screen),
    );
  }

  void _navigateToTask(String taskId, {bool openEdit = false}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          highlightTaskId: taskId,
          openEditSheet: openEdit,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
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
            child: Column(
              children: [
                const GlassAppBar(
                  icon: Icons.notifications_rounded,
                  title: 'Reminders',
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _taskService.tasksStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryDark,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final now = DateTime.now();
                      final upcoming12h = now.add(const Duration(hours: 12));

                      final upcoming = <_ReminderTask>[];
                      final missed = <_ReminderTask>[];

                      for (final doc in docs) {
                        final data = doc.data();
                        final isDone = (data['isDone'] as bool?) ?? false;
                        if (isDone) continue;

                        final dueAt =
                            (data['dueAt'] as Timestamp?)?.toDate();
                        if (dueAt == null) continue;

                        final title = (data['title'] as String?) ?? '';
                        final hasDueTime =
                            (data['hasDueTime'] as bool?) ?? false;

                        if (dueAt.isAfter(now) && dueAt.isBefore(upcoming12h)) {
                          upcoming.add(_ReminderTask(
                            id: doc.id,
                            title: title,
                            dueAt: dueAt,
                            hasDueTime: hasDueTime,
                          ));
                        } else if (dueAt.isBefore(now)) {
                          missed.add(_ReminderTask(
                            id: doc.id,
                            title: title,
                            dueAt: dueAt,
                            hasDueTime: hasDueTime,
                          ));
                        }
                      }

                      upcoming.sort((a, b) => a.dueAt.compareTo(b.dueAt));
                      missed.sort((a, b) => b.dueAt.compareTo(a.dueAt));

                      if (upcoming.isEmpty && missed.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_rounded,
                                size: 64,
                                color: AppColors.outlineVariant,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No reminders',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Reminders for urgently due and missed tasks will appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariantLow,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
                        children: [
                          if (upcoming.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Upcoming Tasks',
                              Icons.access_time_rounded,
                              AppColors.primaryDark,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...upcoming.map((task) => _buildUpcomingCard(task)),
                          ],
                          if (missed.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _buildSectionHeader(
                              'Missed Tasks',
                              Icons.error_rounded,
                              AppColors.error,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...missed.map((task) => _buildMissedCard(task)),
                          ],
                        ],
                      );
                    },
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(_ReminderTask task) {
    final now = DateTime.now();
    final diff = task.dueAt.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    String dueText;

    if (hours > 0 && minutes > 0) {
      dueText = 'Due in ${hours}h ${minutes}m';
    } else if (hours > 0) {
      dueText = 'Due in ${hours}h';
    } else {
      dueText = 'Due in ${minutes}m';
    }

    final timeText = task.hasDueTime ? ' · ${_formatTime(task.dueAt)}' : '';

    return GestureDetector(
      onTap: () => _navigateToTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '$dueText$timeText',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateToTask(task.id),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedCard(_ReminderTask task) {
    final now = DateTime.now();
    final diff = now.difference(task.dueAt);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    String missedText;

    if (diff.inDays >= 1) {
      missedText = 'Missed ${diff.inDays}d ago';
    } else if (hours > 0 && minutes > 0) {
      missedText = 'Missed ${hours}h ${minutes}m ago';
    } else if (hours > 0) {
      missedText = 'Missed ${hours}h ago';
    } else {
      missedText = 'Missed just now';
    }

    final timeText = task.hasDueTime ? ' · ${_formatTime(task.dueAt)}' : '';

    return GestureDetector(
      onTap: () => _navigateToTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusLg,
          boxShadow: [AppShadows.taskCard],
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '$missedText$timeText',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateToTask(task.id, openEdit: true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  child: Text(
                    'Reschedule',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _ReminderTask {
  final String id;
  final String title;
  final DateTime dueAt;
  final bool hasDueTime;

  _ReminderTask({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.hasDueTime,
  });
}
