import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/session.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('sessions');

  Stream<QuerySnapshot<Map<String, dynamic>>> sessionsStream(String uid) {
    return _sessionsRef(uid).orderBy('createdAt', descending: true).snapshots();
  }

  Future<List<Session>> getSessions(String uid) async {
    final snapshot = await _sessionsRef(uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Session.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<String> addSession({
    required String uid,
    required String title,
    required List<SessionItem> items,
  }) async {
    final docRef = await _sessionsRef(uid).add({
      'title': title,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'totalDurationSeconds': items.fold<int>(0, (total, i) => total + i.durationSeconds),
    });
    return docRef.id;
  }

  Future<void> updateSession({
    required String uid,
    required String sessionId,
    required String title,
    required List<SessionItem> items,
  }) async {
    await _sessionsRef(uid).doc(sessionId).update({
      'title': title,
      'items': items.map((i) => i.toMap()).toList(),
      'totalDurationSeconds': items.fold<int>(0, (total, i) => total + i.durationSeconds),
    });
  }

  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    await _sessionsRef(uid).doc(sessionId).delete();
  }

  Future<void> incrementSessionsCompleted(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'sessionsCompleted': FieldValue.increment(1),
    });
  }
}
