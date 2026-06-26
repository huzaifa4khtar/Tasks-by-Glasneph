import 'package:flutter/material.dart';

import '../widgets/timer_notification.dart';

class NotificationService {
  NotificationService._();

  static VoidCallback? onPause;
  static VoidCallback? onResume;
  static VoidCallback? onStop;
  static VoidCallback? onRefresh;
  static VoidCallback? onNext;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await SessionNotification.initialize();
  }

  static void registerCallbacks({
    required VoidCallback pause,
    required VoidCallback resume,
    required VoidCallback stop,
    required VoidCallback refresh,
    required VoidCallback next,
  }) {
    SessionNotification.registerHandlers(
      onPause: pause,
      onResume: resume,
      onStop: stop,
      onRefresh: refresh,
      onNext: next,
    );
  }

  static void clearCallbacks() {
    SessionNotification.clearHandlers();
  }

  static Future<void> show({
    required String sessionName,
    required String taskName,
    required String timeText,
    required double progress,
    required bool isPaused,
  }) async {
    await SessionNotification.show(
      sessionName: sessionName,
      taskName: taskName,
      timeText: timeText,
      progress: progress,
      isPaused: isPaused,
    );
  }

  static Future<void> showComplete({required String sessionName}) async {
    await SessionNotification.showComplete(sessionName: sessionName);
  }

  static Future<void> cancel() async {
    await SessionNotification.cancel();
  }
}
