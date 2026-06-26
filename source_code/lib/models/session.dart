enum SessionItemType { task, break_ }

class SessionItem {
  final String name;
  final int durationSeconds;
  final SessionItemType type;

  const SessionItem({
    required this.name,
    required this.durationSeconds,
    required this.type,
  });

  bool get isTask => type == SessionItemType.task;
  bool get isBreak => type == SessionItemType.break_;

  String get durationLabel {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    if (s > 0) return '${s}s';
    return '0m';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'durationSeconds': durationSeconds,
      'type': type == SessionItemType.task ? 'task' : 'break',
    };
  }

  factory SessionItem.fromMap(Map<String, dynamic> map) {
    return SessionItem(
      name: (map['name'] as String?) ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      type: (map['type'] as String?) == 'break'
          ? SessionItemType.break_
          : SessionItemType.task,
    );
  }

  SessionItem copyWith({
    String? name,
    int? durationSeconds,
    SessionItemType? type,
  }) {
    return SessionItem(
      name: name ?? this.name,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      type: type ?? this.type,
    );
  }
}

class Session {
  final String id;
  final String title;
  final List<SessionItem> items;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.title,
    required this.items,
    required this.createdAt,
  });

  int get totalDurationSeconds =>
      items.fold(0, (sum, item) => sum + item.durationSeconds);

  int get taskCount => items.where((i) => i.isTask).length;

  String get totalDurationLabel {
    final total = totalDurationSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'totalDurationSeconds': totalDurationSeconds,
    };
  }

  factory Session.fromMap(String id, Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((i) => SessionItem.fromMap(i as Map<String, dynamic>))
            .toList() ??
        [];

    DateTime parsedCreatedAt = DateTime.now();
    final raw = map['createdAt'];
    if (raw != null) {
      if (raw is DateTime) {
        parsedCreatedAt = raw;
      } else if (raw is String) {
        parsedCreatedAt = DateTime.tryParse(raw) ?? DateTime.now();
      } else {
        // Firestore Timestamp has a .toDate() method
        try {
          parsedCreatedAt = (raw as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
    }

    return Session(
      id: id,
      title: (map['title'] as String?) ?? '',
      items: itemsList,
      createdAt: parsedCreatedAt,
    );
  }

  Session copyWith({
    String? id,
    String? title,
    List<SessionItem>? items,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
