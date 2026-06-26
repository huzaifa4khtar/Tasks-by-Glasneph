import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/reminder_notification.dart';
import 'reminder_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) {
    return _userDoc(uid).collection('tasks');
  }

  static const List<int> _defaultColors = [
    0xFF8B5CF6,
    0xFF2563EB,
    0xFFF97316,
    0xFF10B981,
    0xFFEC4899,
    0xFF6366F1,
    0xFF14B8A6,
  ];

  static const List<int> _defaultIcons = [
    0xe2c7,
    0xe80c,
    0xe30a,
    0xe8d5,
    0xe3b8,
    0xe334,
    0xe308,
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> tasksStream(String uid) {
    return _tasksRef(uid).snapshots();
  }

  Future<void> addTask({
    required String uid,
    required String title,
    DateTime? dueAt,
    required bool hasDueTime,
    bool isImportant = false,
    String? category,
  }) async {
    final docRef = await _tasksRef(uid).add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt) : null,
      'hasDueTime': hasDueTime,
      'isDone': false,
      'isImportant': isImportant,
      'category': category,
    });

    if (dueAt != null) {
      try {
        await ReminderService.scheduleReminders(
          taskId: docRef.id,
          title: title,
          dueAt: dueAt,
        );
      } catch (_) {
      }
    }
  }

  Future<void> toggleTask({
    required String uid,
    required String taskId,
    required bool isDone,
  }) async {
    await _tasksRef(uid).doc(taskId).update({'isDone': !isDone});
    if (!isDone) {
      try {
        await ReminderService.cancelReminders(taskId: taskId);
      } catch (_) {
      }
    }
  }

  Future<void> toggleImportant({
    required String uid,
    required String taskId,
    required bool isImportant,
  }) async {
    await _tasksRef(uid).doc(taskId).update({'isImportant': !isImportant});
  }

  Future<void> updateTask({
    required String uid,
    required String taskId,
    required String title,
    DateTime? dueAt,
    required bool hasDueTime,
  }) async {
    await _tasksRef(uid).doc(taskId).update({
      'title': title,
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt) : null,
      'hasDueTime': hasDueTime,
    });

    try {
      await ReminderService.cancelReminders(taskId: taskId);
      if (dueAt != null) {
        await ReminderService.scheduleReminders(
          taskId: taskId,
          title: title,
          dueAt: dueAt,
        );
      }
    } catch (_) {
    }
  }

  Future<void> deleteTask({
    required String uid,
    required String taskId,
  }) async {
    await _tasksRef(uid).doc(taskId).delete();
    try {
      await ReminderService.cancelReminders(taskId: taskId);
    } catch (_) {
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> listsStream(String uid) {
    return _userDoc(uid).snapshots();
  }

  Future<void> rescheduleAllReminders(String uid) async {
    try {
      final snapshot = await _tasksRef(uid).where('isDone', isEqualTo: false).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dueAt = (data['dueAt'] as Timestamp?)?.toDate();
        final title = (data['title'] as String?) ?? '';
        if (dueAt == null) continue;
        final numericId = ReminderService.taskIdFromString(doc.id);

        await ReminderNotification.cancelAll(numericId);
        await ReminderNotification.scheduleFutureOnly(
          taskId: numericId, title: title, dueAt: dueAt,
        );
      }
    } catch (_) {
    }
  }

  Future<Map<String, Map<String, dynamic>>> getLists(String uid) async {
    final snapshot = await _userDoc(uid).get();
    final data = snapshot.data();
    if (data == null) return {};
    final raw = data['customLists'] as Map<String, dynamic>?;
    if (raw == null) return {};
    return raw.map((key, value) {
      final map = (value as Map<String, dynamic>?) ?? {};
      return MapEntry(key, map);
    });
  }

  Future<String> addList({
    required String uid,
    required String name,
    int? iconCodePoint,
    int? colorValue,
  }) async {
    final existingLists = await getLists(uid);
    final duplicate = existingLists.values.any(
      (l) => (l['name'] as String?)?.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('A list with this name already exists.');
    }

    final listId = 'list_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final colorIndex = existingLists.length % _defaultColors.length;
    final iconIndex = existingLists.length % _defaultIcons.length;

    await _userDoc(uid).update({
      'customLists.$listId': {
        'name': name,
        'iconCodePoint': iconCodePoint ?? _defaultIcons[iconIndex],
        'colorValue': colorValue ?? _defaultColors[colorIndex],
        'createdAt': FieldValue.serverTimestamp(),
      },
    });
    return listId;
  }

  Future<void> deleteList({
    required String uid,
    required String listId,
  }) async {
    await _userDoc(uid).update({
      'customLists.$listId': FieldValue.delete(),
    });
  }
}
