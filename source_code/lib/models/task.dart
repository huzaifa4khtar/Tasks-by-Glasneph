import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? dueAt;
  final bool hasDueTime;
  final bool isDone;
  final bool isImportant;
  final String? category;

  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.dueAt,
    this.hasDueTime = false,
    this.isDone = false,
    this.isImportant = false,
    this.category,
  });

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: (data['title'] as String?) ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      dueAt: data['dueAt'] != null ? _parseTimestamp(data['dueAt']) : null,
      hasDueTime: (data['hasDueTime'] as bool?) ?? false,
      isDone: (data['isDone'] as bool?) ?? false,
      isImportant: (data['isImportant'] as bool?) ?? false,
      category: data['category'] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'hasDueTime': hasDueTime,
      'isDone': isDone,
      'isImportant': isImportant,
      'category': category,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? dueAt,
    bool? hasDueTime,
    bool? isDone,
    bool? isImportant,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      hasDueTime: hasDueTime ?? this.hasDueTime,
      isDone: isDone ?? this.isDone,
      isImportant: isImportant ?? this.isImportant,
      category: category ?? this.category,
    );
  }
}
