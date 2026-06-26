import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';

@pragma("vm:entry-point")
class SessionNotification {
  SessionNotification._();

  static const int id = 1001;
  static const int completeId = 1002;
  static const String channelKey = 'session_timer';
  static const String channelName = 'Session Timer';
  static const String channelDesc = 'Shows session timer while running';

  static const String completeChannelKey = 'session_complete_v2';
  static const String completeChannelName = 'Session Complete';
  static const String completeChannelDesc = 'Notifies when a session is completed';

  static const String actionPause = 'session_pause';
  static const String actionResume = 'session_resume';
  static const String actionStop = 'session_stop';
  static const String actionRefresh = 'session_refresh';
  static const String actionNext = 'session_next';

  static VoidCallback? onPause;
  static VoidCallback? onResume;
  static VoidCallback? onStop;
  static VoidCallback? onRefresh;
  static VoidCallback? onNext;

  static void Function(ReceivedAction)? onReminderAction;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceived(ReceivedAction received) async {
    final channelKey = received.channelKey;
    if (channelKey == 'task_reminders') {
      onReminderAction?.call(received);
      return;
    }

    final key = received.buttonKeyPressed;
    if (key.isEmpty) return;

    switch (key) {
      case actionPause:
        onPause?.call();
        break;
      case actionResume:
        onResume?.call();
        break;
      case actionStop:
        onStop?.call();
        break;
      case actionRefresh:
        onRefresh?.call();
        break;
      case actionNext:
        onNext?.call();
        break;
    }
  }

  static void registerHandlers({
    required VoidCallback onPause,
    required VoidCallback onResume,
    required VoidCallback onStop,
    required VoidCallback onRefresh,
    required VoidCallback onNext,
  }) {
    SessionNotification.onPause = onPause;
    SessionNotification.onResume = onResume;
    SessionNotification.onStop = onStop;
    SessionNotification.onRefresh = onRefresh;
    SessionNotification.onNext = onNext;
  }

  static void clearHandlers() {
    SessionNotification.onPause = null;
    SessionNotification.onResume = null;
    SessionNotification.onStop = null;
    SessionNotification.onRefresh = null;
    SessionNotification.onNext = null;
  }

  static Future<void> _ensurePermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> show({
    required String sessionName,
    required String taskName,
    required String timeText,
    required double progress,
    required bool isPaused,
  }) async {
    await _ensurePermission();

    final pauseBtn = NotificationActionButton(
      key: actionPause,
      label: 'Pause',
      icon: 'resource://drawable/ic_notification_pause',
      actionType: ActionType.KeepOnTop,
      autoDismissible: false,
    );

    final resumeBtn = NotificationActionButton(
      key: actionResume,
      label: 'Resume',
      icon: 'resource://drawable/ic_notification_play',
      actionType: ActionType.KeepOnTop,
      autoDismissible: false,
    );

    final refreshBtn = NotificationActionButton(
      key: actionRefresh,
      label: 'Refresh',
      icon: 'resource://drawable/ic_notification_refresh',
      actionType: ActionType.KeepOnTop,
      autoDismissible: false,
    );

    final nextBtn = NotificationActionButton(
      key: actionNext,
      label: 'Next',
      icon: 'resource://drawable/ic_notification_next',
      actionType: ActionType.KeepOnTop,
      autoDismissible: false,
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: sessionName,
        body: '$taskName - $timeText',
        notificationLayout: NotificationLayout.MediaPlayer,
        largeIcon: 'resource://mipmap/ic_launcher',
        roundedLargeIcon: true,
        progress: progress.clamp(0.0, 100.0),
        payload: {'screen': 'session'},
        category: NotificationCategory.StopWatch,
        color: AppColors.primaryDark,
        displayOnForeground: true,
        displayOnBackground: true,
        autoDismissible: false,
      ),
      actionButtons: [
        refreshBtn,
        if (isPaused) resumeBtn else pauseBtn,
        nextBtn,
      ],
    );
  }

  static Future<void> showComplete({required String sessionName}) async {
    await _ensurePermission();

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: completeId,
          channelKey: completeChannelKey,
          title: 'Session Complete!',
          body: 'Great work! You completed "$sessionName".',
          notificationLayout: NotificationLayout.Default,
          payload: {'screen': 'session'},
          category: NotificationCategory.Status,
          color: AppColors.success,
        ),
      );
    } catch (_) {
    }
  }

  static Future<void> cancel() async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
}
