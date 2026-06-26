import '../widgets/reminder_notification.dart';

class ReminderService {
  ReminderService._();

  static int taskIdFromString(String taskId) {
    return taskId.hashCode.abs() % 2147483647;
  }

  static Future<void> scheduleReminders({
    required String taskId,
    required String title,
    required DateTime dueAt,
  }) async {
    final numericId = taskIdFromString(taskId);

    await ReminderNotification.scheduleAll(
      taskId: numericId,
      title: title,
      dueAt: dueAt,
    );
  }

  static Future<void> cancelReminders({
    required String taskId,
  }) async {
    final numericId = taskIdFromString(taskId);
    await ReminderNotification.cancelAll(numericId);
  }
}
