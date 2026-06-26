import 'package:awesome_notifications/awesome_notifications.dart';

import '../constants.dart';

class ReminderNotification {
  ReminderNotification._();

  static const String channelKey = 'task_reminders';
  static const String channelName = 'Task Reminders';
  static const String channelDesc = 'Reminds you about upcoming and missed tasks';

  static const String actionView = 'reminder_view';
  static const String actionReschedule = 'reminder_reschedule';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  static Future<void> ensurePermissions() async {
    try {
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    } catch (_) {
    }
  }

  static Future<void> scheduleAll({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    await ensurePermissions();
    final now = DateTime.now();

    if (dueAt.isBefore(now)) {
      await _fireMissed(taskId: taskId, title: title, dueAt: dueAt);
    } else if (dueAt.subtract(const Duration(hours: 2)).isBefore(now)) {
      await _fire2h(taskId: taskId, title: title, dueAt: dueAt);
    } else if (dueAt.subtract(const Duration(hours: 12)).isBefore(now)) {
      await _fire12h(taskId: taskId, title: title, dueAt: dueAt);
    } else {
      await _scheduleFuture12h(taskId: taskId, title: title, dueAt: dueAt);
      await _scheduleFuture2h(taskId: taskId, title: title, dueAt: dueAt);
      await _scheduleFutureMissed(taskId: taskId, title: title, dueAt: dueAt);
    }
  }

  static Future<void> scheduleFutureOnly({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    await _scheduleFuture12h(taskId: taskId, title: title, dueAt: dueAt);
    await _scheduleFuture2h(taskId: taskId, title: title, dueAt: dueAt);
    await _scheduleFutureMissed(taskId: taskId, title: title, dueAt: dueAt);
  }

  static Future<void> cancelAll(int taskId) async {
    await AwesomeNotifications().cancel(_generateId(taskId, 0));
    await AwesomeNotifications().cancel(_generateId(taskId, 1));
    await AwesomeNotifications().cancel(_generateId(taskId, 2));
  }

  static Future<void> cancelAllReminders() async {
    await AwesomeNotifications().cancelAll();
  }

  static Future<void> _fireMissed({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    final notificationId = _generateId(taskId, 2);
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: 'Missed Task',
          body: 'Task Title: "$title"',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': taskId.toString(), 'type': 'missed'},
          category: NotificationCategory.Reminder,
          color: AppColors.error,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionReschedule,
            label: 'Reschedule',
            actionType: ActionType.Default,
            autoDismissible: false,
          ),
        ],
      );
    } catch (_) {
    }
  }

  static Future<void> _fire2h({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    final notificationId = _generateId(taskId, 1);
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: 'Task Due in 2 Hours',
          body: 'Task Title: "$title"',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': taskId.toString(), 'type': 'upcoming_2h'},
          category: NotificationCategory.Reminder,
          color: AppColors.primaryDark,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionView,
            label: 'View',
            actionType: ActionType.Default,
            autoDismissible: false,
          ),
        ],
      );
    } catch (_) {
    }
  }

  static Future<void> _fire12h({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    final notificationId = _generateId(taskId, 0);
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: 'Task Due in 12 Hours',
          body: 'Task Title: "$title"',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': taskId.toString(), 'type': 'upcoming_12h'},
          category: NotificationCategory.Reminder,
          color: AppColors.primaryDark,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionView,
            label: 'View',
            actionType: ActionType.Default,
            autoDismissible: false,
          ),
        ],
      );
    } catch (_) {
    }
  }

  static Future<void> _scheduleFuture12h({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    final scheduledTime = dueAt.subtract(const Duration(hours: 12));
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateId(taskId, 0),
          channelKey: channelKey,
          title: 'Task Due in 12 Hours',
          body: 'Task Title: "$title"',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': taskId.toString(), 'type': 'upcoming_12h'},
          category: NotificationCategory.Reminder,
          color: AppColors.primaryDark,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionView,
            label: 'View',
            actionType: ActionType.Default,
            autoDismissible: false,
          ),
        ],
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          preciseAlarm: false,
          allowWhileIdle: true,
        ),
      );
    } catch (_) {
    }
  }

  static Future<void> _scheduleFuture2h({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    final scheduledTime = dueAt.subtract(const Duration(hours: 2));
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateId(taskId, 1),
          channelKey: channelKey,
          title: 'Task Due in 2 Hours',
          body: 'Task Title: "$title"',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': taskId.toString(), 'type': 'upcoming_2h'},
          category: NotificationCategory.Reminder,
          color: AppColors.primaryDark,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionView,
            label: 'View',
            actionType: ActionType.Default,
            autoDismissible: false,
          ),
        ],
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          preciseAlarm: false,
          allowWhileIdle: true,
        ),
      );
    } catch (_) {
    }
  }

  static Future<void> _scheduleFutureMissed({
    required int taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    if (dueAt.isBefore(DateTime.now())) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateId(taskId, 2),
          channelKey: channelKey,
          title: 'Missed Task',
          body: 'Task Title: "$title"',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': taskId.toString(), 'type': 'missed'},
          category: NotificationCategory.Reminder,
          color: AppColors.error,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionReschedule,
            label: 'Reschedule',
            actionType: ActionType.Default,
            autoDismissible: false,
          ),
        ],
        schedule: NotificationCalendar(
          year: dueAt.year,
          month: dueAt.month,
          day: dueAt.day,
          hour: dueAt.hour,
          minute: dueAt.minute,
          second: 0,
          preciseAlarm: false,
          allowWhileIdle: true,
        ),
      );
    } catch (_) {
    }
  }

  static int _generateId(int taskId, int typeIndex) {
    final third = 715827882;
    return (taskId % third) + (typeIndex * third);
  }

}
