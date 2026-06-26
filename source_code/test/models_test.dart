import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasks/models/task.dart';
import 'package:tasks/models/session.dart';
import 'package:tasks/services/reminder_service.dart';

void main() {
  group('Task model', () {
    test('creates with required fields', () {
      final now = DateTime(2025, 6, 25, 10, 0);
      final task = Task(
        id: 'abc',
        title: 'Buy milk',
        createdAt: now,
      );

      expect(task.id, 'abc');
      expect(task.title, 'Buy milk');
      expect(task.createdAt, now);
      expect(task.dueAt, isNull);
      expect(task.hasDueTime, false);
      expect(task.isDone, false);
      expect(task.isImportant, false);
      expect(task.category, isNull);
    });

    test('creates with all optional fields', () {
      final now = DateTime(2025, 6, 25, 10, 0);
      final due = DateTime(2025, 6, 26, 14, 30);
      final task = Task(
        id: 'xyz',
        title: 'Write report',
        createdAt: now,
        dueAt: due,
        hasDueTime: true,
        isDone: true,
        isImportant: true,
        category: 'Work',
      );

      expect(task.id, 'xyz');
      expect(task.title, 'Write report');
      expect(task.dueAt, due);
      expect(task.hasDueTime, true);
      expect(task.isDone, true);
      expect(task.isImportant, true);
      expect(task.category, 'Work');
    });

    test('copyWith creates new instance with overrides', () {
      final now = DateTime(2025, 6, 25);
      final task = Task(id: '1', title: 'Old', createdAt: now);

      final updated = task.copyWith(title: 'New', isDone: true);

      expect(updated.id, '1');
      expect(updated.title, 'New');
      expect(updated.isDone, true);
      expect(updated.createdAt, now); // unchanged
    });

    test('copyWith without arguments returns equivalent instance', () {
      final now = DateTime(2025, 6, 25);
      final task = Task(id: '1', title: 'Test', createdAt: now);
      final copy = task.copyWith();

      expect(copy.id, task.id);
      expect(copy.title, task.title);
      expect(copy.createdAt, task.createdAt);
    });

    test('toFirestore produces correct map', () {
      final now = DateTime(2025, 6, 25, 10, 0);
      final due = DateTime(2025, 6, 26, 14, 0);
      final task = Task(
        id: '1',
        title: 'Test',
        createdAt: now,
        dueAt: due,
        hasDueTime: true,
        isDone: false,
        isImportant: true,
        category: 'Study',
      );

      final data = task.toFirestore();

      expect(data['title'], 'Test');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['dueAt'], isA<Timestamp>());
      expect(data['hasDueTime'], true);
      expect(data['isDone'], false);
      expect(data['isImportant'], true);
      expect(data['category'], 'Study');
    });

    test('toFirestore with null dueAt maps to null', () {
      final task = Task(
        id: '1',
        title: 'Test',
        createdAt: DateTime(2025, 6, 25),
      );

      final data = task.toFirestore();
      expect(data['dueAt'], isNull);
    });
  });

  group('SessionItem model', () {
    test('creates task item', () {
      const item = SessionItem(
        name: 'Read chapter',
        durationSeconds: 1800,
        type: SessionItemType.task,
      );

      expect(item.name, 'Read chapter');
      expect(item.durationSeconds, 1800);
      expect(item.isTask, true);
      expect(item.isBreak, false);
    });

    test('creates break item', () {
      const item = SessionItem(
        name: 'Break',
        durationSeconds: 300,
        type: SessionItemType.break_,
      );

      expect(item.isTask, false);
      expect(item.isBreak, true);
    });

    test('durationLabel formats hours and minutes', () {
      const item = SessionItem(
        name: 'Task',
        durationSeconds: 3660, // 1h 1m
        type: SessionItemType.task,
      );

      expect(item.durationLabel, '1h 1m');
    });

    test('durationLabel formats minutes and seconds', () {
      const item = SessionItem(
        name: 'Task',
        durationSeconds: 125, // 2m 5s
        type: SessionItemType.task,
      );

      expect(item.durationLabel, '2m 5s');
    });

    test('durationLabel formats minutes only', () {
      const item = SessionItem(
        name: 'Task',
        durationSeconds: 300, // 5m
        type: SessionItemType.task,
      );

      expect(item.durationLabel, '5m');
    });

    test('durationLabel formats seconds only', () {
      const item = SessionItem(
        name: 'Task',
        durationSeconds: 45, // 45s
        type: SessionItemType.task,
      );

      expect(item.durationLabel, '45s');
    });

    test('durationLabel returns 0m for zero seconds', () {
      const item = SessionItem(
        name: 'Task',
        durationSeconds: 0,
        type: SessionItemType.task,
      );

      expect(item.durationLabel, '0m');
    });

    test('toMap and fromMap round-trip', () {
      const item = SessionItem(
        name: 'Write code',
        durationSeconds: 900,
        type: SessionItemType.task,
      );

      final map = item.toMap();
      final restored = SessionItem.fromMap(map);

      expect(restored.name, item.name);
      expect(restored.durationSeconds, item.durationSeconds);
      expect(restored.type, SessionItemType.task);
    });

    test('fromMap handles break type', () {
      final map = {
        'name': 'Break',
        'durationSeconds': 300,
        'type': 'break',
      };

      final item = SessionItem.fromMap(map);
      expect(item.isBreak, true);
    });

    test('copyWith creates new instance with overrides', () {
      const item = SessionItem(
        name: 'Task',
        durationSeconds: 300,
        type: SessionItemType.task,
      );

      final updated = item.copyWith(name: 'Updated', durationSeconds: 600);

      expect(updated.name, 'Updated');
      expect(updated.durationSeconds, 600);
      expect(updated.type, SessionItemType.task); // unchanged
    });
  });

  group('Session model', () {
    test('totalDurationSeconds sums all items', () {
      final session = Session(
        id: 's1',
        title: 'Study',
        items: [
          const SessionItem(name: 'Read', durationSeconds: 600, type: SessionItemType.task),
          const SessionItem(name: 'Break', durationSeconds: 300, type: SessionItemType.break_),
          const SessionItem(name: 'Write', durationSeconds: 900, type: SessionItemType.task),
        ],
        createdAt: DateTime(2025, 6, 25),
      );

      expect(session.totalDurationSeconds, 1800); // 30 min
    });

    test('taskCount counts only tasks', () {
      final session = Session(
        id: 's1',
        title: 'Study',
        items: [
          const SessionItem(name: 'Read', durationSeconds: 600, type: SessionItemType.task),
          const SessionItem(name: 'Break', durationSeconds: 300, type: SessionItemType.break_),
          const SessionItem(name: 'Write', durationSeconds: 900, type: SessionItemType.task),
          const SessionItem(name: 'Break', durationSeconds: 300, type: SessionItemType.break_),
        ],
        createdAt: DateTime(2025, 6, 25),
      );

      expect(session.taskCount, 2);
    });

    test('totalDurationLabel formats hours and minutes', () {
      final session = Session(
        id: 's1',
        title: 'Long',
        items: [
          const SessionItem(name: 'Task', durationSeconds: 5400, type: SessionItemType.task), // 90 min = 1h 30m
        ],
        createdAt: DateTime(2025, 6, 25),
      );

      expect(session.totalDurationLabel, '1h 30m');
    });

    test('totalDurationLabel formats minutes only', () {
      final session = Session(
        id: 's1',
        title: 'Short',
        items: [
          const SessionItem(name: 'Task', durationSeconds: 1200, type: SessionItemType.task), // 20 min
        ],
        createdAt: DateTime(2025, 6, 25),
      );

      expect(session.totalDurationLabel, '20m');
    });

    test('copyWith creates new instance with overrides', () {
      final session = Session(
        id: 's1',
        title: 'Old',
        items: [],
        createdAt: DateTime(2025, 6, 25),
      );

      final updated = session.copyWith(title: 'New');

      expect(updated.id, 's1');
      expect(updated.title, 'New');
      expect(updated.items, isEmpty);
    });
  });

  group('ReminderService.taskIdFromString', () {
    test('produces consistent numeric IDs', () {
      final id1 = ReminderService.taskIdFromString('abc123');
      final id2 = ReminderService.taskIdFromString('abc123');
      expect(id1, id2);
    });

    test('produces different IDs for different inputs', () {
      final id1 = ReminderService.taskIdFromString('task_a');
      final id2 = ReminderService.taskIdFromString('task_b');
      expect(id1, isNot(equals(id2)));
    });

    test('produces positive integers', () {
      final id = ReminderService.taskIdFromString('any-task-id');
      expect(id, greaterThan(0));
    });

    test('produces values within int32 range', () {
      final id = ReminderService.taskIdFromString('test');
      expect(id, lessThanOrEqualTo(2147483647));
    });
  });
}
