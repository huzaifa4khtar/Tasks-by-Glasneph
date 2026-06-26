import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/slide_route.dart';
import 'sessions_list_screen.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final Session session;

  const ActiveSessionScreen({super.key, required this.session});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  Timer? _timer;
  late AnimationController _progressController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  final List<_ItemStatus> _statuses = [];
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _statuses.addAll(
      widget.session.items.map((_) => _ItemStatus.pending),
    );
    _secondsRemaining = widget.session.items.first.durationSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsRemaining),
    );
    _progressController.value = 1.0;

    _floatController = AnimationController(
      vsync: this,
      duration: AppDurations.veryLong,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    NotificationService.registerCallbacks(
      pause: _pause,
      resume: _start,
      stop: _stop,
      refresh: _refresh,
      next: _skip,
    );
  }

  @override
  void dispose() {
    NotificationService.cancel();
    NotificationService.clearCallbacks();
    _timer?.cancel();
    _progressController.dispose();
    _floatController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  int get _totalDuration =>
      widget.session.items[_currentIndex].durationSeconds;

  bool get _isSessionComplete => _statuses.every(
        (s) => s == _ItemStatus.completed || s == _ItemStatus.skipped,
      );

  void _start() {
    setState(() => _isRunning = true);

    _progressController.duration = Duration(seconds: _totalDuration);
    _progressController.reverse(from: 1.0);

    final currentItem = widget.session.items[_currentIndex];
    final progressPct = _totalDuration > 0
        ? (_secondsRemaining / _totalDuration) * 100
        : 0.0;
    NotificationService.show(
      sessionName: widget.session.title,
      taskName: currentItem.isTask ? currentItem.name : 'Break',
      timeText: _formatTime(_secondsRemaining),
      progress: progressPct,
      isPaused: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        final currentItem = widget.session.items[_currentIndex];
        final progressPct = _totalDuration > 0
            ? (_secondsRemaining / _totalDuration) * 100
            : 0.0;
        NotificationService.show(
          sessionName: widget.session.title,
          taskName: currentItem.isTask ? currentItem.name : 'Break',
          timeText: _formatTime(_secondsRemaining),
          progress: progressPct,
          isPaused: false,
        );
        if (_secondsRemaining <= 0) {
          _completeCurrentItem();
        }
      } else {
        _pause();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _progressController.stop();
    setState(() => _isRunning = false);
    final currentItem = widget.session.items[_currentIndex];
    final progressPct = _totalDuration > 0
        ? (_secondsRemaining / _totalDuration) * 100
        : 0.0;
    NotificationService.show(
      sessionName: widget.session.title,
      taskName: currentItem.isTask ? currentItem.name : 'Break',
      timeText: _formatTime(_secondsRemaining),
      progress: progressPct,
      isPaused: true,
    );
  }

  void _refresh() {
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _totalDuration;
      _progressController.value = 1.0;
    });
    final currentItem = widget.session.items[_currentIndex];
    final progressPct = _totalDuration > 0
        ? (_secondsRemaining / _totalDuration) * 100
        : 0.0;
    NotificationService.show(
      sessionName: widget.session.title,
      taskName: currentItem.isTask ? currentItem.name : 'Break',
      timeText: _formatTime(_secondsRemaining),
      progress: progressPct,
      isPaused: true,
    );
  }

  void _skip() {
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      _statuses[_currentIndex] = _ItemStatus.skipped;
    });
    _moveToNext();
  }

  void _completeCurrentItem() {
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      _statuses[_currentIndex] = _ItemStatus.completed;
      _isRunning = false;
    });
    _moveToNext();
  }

  void _moveToNext() {
    if (_currentIndex < widget.session.items.length - 1) {
      setState(() {
        _currentIndex++;
        _secondsRemaining = _totalDuration;
        _progressController.value = 1.0;
      });
      _scrollToCurrentItem();
      _start();
    } else {
      NotificationService.cancel();
      _finishSession();
    }
  }

  void _scrollToCurrentItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_timelineScrollController.hasClients) {
        final targetOffset = (_currentIndex * 30.0).clamp(
          0.0,
          _timelineScrollController.position.maxScrollExtent,
        );
        _timelineScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _progressController.stop();
    NotificationService.cancel();
    Navigator.pushReplacement(
      context,
      fadeRoute(const SessionsListScreen()),
    );
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      _isRunning = false;
      _secondsRemaining = 0;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(sessionServiceProvider).incrementSessionsCompleted(user.uid);
    }
    await NotificationService.cancel();
    await NotificationService.showComplete(sessionName: widget.session.title);
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.session.items[_currentIndex];
    final isComplete = _isSessionComplete;
    final progress = isComplete
        ? 1.0
        : _totalDuration > 0
            ? _secondsRemaining / _totalDuration
            : 0.0;

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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.containerPadding,
                      right: AppSpacing.containerPadding,
                      top: AppSpacing.xl,
                      bottom: 160,
                    ),
                    child: Column(
                      children: [
                        _buildTimerDisplay(progress, currentItem),
                        const SizedBox(height: AppSpacing.xl),
                        _buildTimeline(),
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
            bottom: 0,
            child: _buildControls(),
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
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorderLight),
        ),
      ),
      child: SizedBox(
        height: AppComponentSizes.headerHeight,
        child: Row(
          children: [
            GestureDetector(
              onTap: _stop,
              child: const Icon(
                Icons.arrow_back_rounded,
                size: AppIconSizes.header,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                widget.session.title,
                style: AppTextStyles.headlineSm,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(double progress, SessionItem currentItem) {
    final isComplete = _isSessionComplete;
    final accentColor = isComplete
        ? AppColors.success
        : currentItem.isTask
            ? AppColors.primaryDark
            : AppColors.success;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_secondsRemaining),
                  style: AppTextStyles.displayLg.copyWith(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusPill,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isComplete
                            ? 'Session Completed'
                            : currentItem.isTask
                                ? currentItem.name
                                : 'Break',
                        style: AppTextStyles.labelMd.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.session.title.toUpperCase(),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.outline,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.session.totalDurationLabel,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: _timelineScrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.session.items.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.session.items.length) {
                  return _buildSessionCompleteItem();
                }
                final item = widget.session.items[index];
                final status = _statuses[index];
                final isCurrent = index == _currentIndex;

                return _buildTimelineItem(item, status, isCurrent, false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    SessionItem item,
    _ItemStatus status,
    bool isCurrent,
    bool isLast,
  ) {
    final isCompleted = status == _ItemStatus.completed;
    final isSkipped = status == _ItemStatus.skipped;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildTimelineDot(status, isCurrent),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      item.isTask ? item.name : 'Break',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.primaryDark
                            : isCompleted
                                ? AppColors.primaryDark
                                : isSkipped
                                    ? AppColors.outlineVariant
                                    : AppColors.onSurfaceVariant,
                        decoration: isSkipped
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    item.durationLabel,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isCurrent
                          ? AppColors.primaryDark
                          : AppColors.onSurfaceVariant,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(_ItemStatus status, bool isCurrent) {
    if (isCurrent) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 16,
          color: AppColors.onPrimary,
        ),
      );
    }

    switch (status) {
      case _ItemStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: AppColors.onPrimary,
          ),
        );
      case _ItemStatus.skipped:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(
            Icons.remove_rounded,
            size: 12,
            color: AppColors.outlineVariant,
          ),
        );
      case _ItemStatus.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.outline,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildSessionCompleteItem() {
    final allDone = _statuses.every(
      (s) => s == _ItemStatus.completed || s == _ItemStatus.skipped,
    );
    final color = allDone ? AppColors.success : AppColors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allDone ? Icons.emoji_events_rounded : Icons.circle_outlined,
                    size: 14,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Text(
                'Session Completed',
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final done = _isSessionComplete;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.refresh_rounded,
            onTap: done ? null : _refresh,
            size: 56,
            bgColor: done ? AppColors.surfaceContainerHigh : AppColors.surface,
            iconColor: done ? AppColors.onSurfaceVariant : AppColors.primaryDark,
          ),
          const SizedBox(width: AppSpacing.xl),
          _buildControlButton(
            icon:
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: done ? null : (_isRunning ? _pause : _start),
            size: 96,
            bgColor: done ? AppColors.surfaceContainerHigh : AppColors.primaryDark,
            iconColor: done ? AppColors.onSurfaceVariant : AppColors.onPrimary,
            shadow: done ? null : AppShadows.primaryButton,
          ),
          const SizedBox(width: AppSpacing.xl),
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            onTap: done ? null : _skip,
            size: 56,
            bgColor: done ? AppColors.surfaceContainerHigh : AppColors.surface,
            iconColor: done ? AppColors.onSurfaceVariant : AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
    required double size,
    required Color bgColor,
    required Color iconColor,
    Color? borderColor,
    BoxShadow? shadow,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border:
              borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: shadow != null ? [shadow] : null,
        ),
        child: Icon(icon, size: size * 0.42, color: iconColor),
      ),
    );
  }
}

enum _ItemStatus { pending, completed, skipped }
